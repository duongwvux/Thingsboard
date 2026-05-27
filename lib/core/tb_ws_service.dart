import 'dart:async';
import 'dart:convert';
import 'package:web_socket_client/web_socket_client.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// Một message push từ ThingsBoard WS — đã parse sẵn
class TelemetryMessage {
  final String deviceId;

  /// telemetry key → giá trị mới nhất (double)
  final Map<String, double> values;

  /// null = message này không phải attribute, true/false = trạng thái active
  final bool? isOnline;

  const TelemetryMessage({
    required this.deviceId,
    required this.values,
    this.isOnline,
  });
}

// ---------------------------------------------------------------------------
// TbWebSocketService
// ---------------------------------------------------------------------------
//
// - Một kết nối WebSocket dùng chung cho toàn app
// - web_socket_client tự reconnect với BinaryExponentialBackOff
// - Khi reconnect → tự re-subscribe tất cả device đã đăng ký
//
// Cách dùng:
//   final ws = TbWebSocketService(baseUrl: '...', token: '...');
//   ws.subscribeDevice('device-id');
//   ws.messages.listen((msg) { ... });
//   ws.dispose();
// ---------------------------------------------------------------------------

class TbWebSocketService {
  late final WebSocket _socket;

  // cmdId → deviceId (để map response về đúng device)
  final _cmdToDevice = <int, String>{};

  // deviceId → payload (để re-subscribe khi reconnect)
  final _activeSubs = <String, Map<String, dynamic>>{};

  int _nextCmdId = 1;

  // Broadcast stream đã parse — nhiều provider cùng lắng nghe
  late final Stream<TelemetryMessage> messages;

  TbWebSocketService({required String baseUrl, required String token}) {
    final wsUrl = baseUrl
        .replaceFirst(RegExp(r'^https'), 'wss')
        .replaceFirst(RegExp(r'^http'), 'ws');

    _socket = WebSocket(
      Uri.parse('$wsUrl/api/ws/plugins/telemetry?token=$token'),
      // Tự reconnect: 1s → 2s → 4s → 8s → tối đa 32s
      backoff: BinaryExponentialBackoff(
        initial: Duration(seconds: 1),
        maximumStep: 5,
      ),
    );

    // Re-subscribe toàn bộ device sau khi mất kết nối và kết nối lại
    _socket.connection.listen((state) {
      if (state is Reconnected) _resubscribeAll();
    });

    // Parse raw string → TelemetryMessage, broadcast cho mọi subscriber
    messages = _socket.messages
        .map<Map<String, dynamic>?>((raw) {
          if (raw is! String) return null;
          try {
            return jsonDecode(raw) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .where((json) => json != null && json.containsKey('subscriptionId'))
        .map<TelemetryMessage?>((json) => _parse(json!))
        .where((m) => m != null)
        .cast<TelemetryMessage>()
        .asBroadcastStream();
  }

  // ── Public API ─────────────────────────────────────────────────────────

  Stream<ConnectionState> get connectionState => _socket.connection;

  /// Subscribe telemetry + server attributes của một device.
  /// Gọi nhiều lần với cùng deviceId thì không-op.
  void subscribeDevice(String deviceId) {
    if (_activeSubs.containsKey(deviceId)) return;

    final tsCmdId   = _nextCmdId++;
    final attrCmdId = _nextCmdId++;

    _cmdToDevice[tsCmdId]   = deviceId;
    _cmdToDevice[attrCmdId] = deviceId;

    final payload = {
      'tsSubCmds': [
        {
          'entityType': 'DEVICE',
          'entityId': deviceId,
          'scope': 'LATEST_TELEMETRY',
          'cmdId': tsCmdId,
        }
      ],
      'attrSubCmds': [
        {
          'entityType': 'DEVICE',
          'entityId': deviceId,
          'scope': 'SERVER_SCOPE',
          'cmdId': attrCmdId,
        }
      ],
    };

    _activeSubs[deviceId] = payload;
    _socket.send(jsonEncode(payload));
  }

  void dispose() => _socket.close();

  // ── Internal ───────────────────────────────────────────────────────────

  void _resubscribeAll() {
    for (final payload in _activeSubs.values) {
      _socket.send(jsonEncode(payload));
    }
  }

  TelemetryMessage? _parse(Map<String, dynamic> json) {
    final cmdId    = json['subscriptionId'] as int?;
    final deviceId = cmdId != null ? _cmdToDevice[cmdId] : null;
    if (deviceId == null) return null;

    final rawData = json['data'] as Map<String, dynamic>? ?? {};
    final values  = <String, double>{};
    bool? isOnline;

    for (final entry in rawData.entries) {
      final points = entry.value as List<dynamic>;
      if (points.isEmpty) continue;

      // ThingsBoard trả dạng [[ts, "value"], ...]
      // Phần tử đầu tiên = mới nhất
      final first = points.first;
      if (first is! List || first.length < 2) continue;

      final valStr = first[1].toString();

      if (entry.key == 'active') {
        isOnline = valStr == 'true' || first[1] == true;
      } else {
        final d = double.tryParse(valStr);
        if (d != null) values[entry.key] = d;
      }
    }

    // Bỏ qua message trống
    if (values.isEmpty && isOnline == null) return null;

    return TelemetryMessage(
      deviceId: deviceId,
      values: values,
      isOnline: isOnline,
    );
  }
}