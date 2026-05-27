import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_constants.dart';
import '../../core/dio_client.dart';
import '../../core/tb_ws_service.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_state.dart';
import 'dashboard_tile_config.dart';
import 'telemetry_model.dart';
import 'tb_telemetry_service.dart';

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

final tbTelemetryServiceProvider = Provider<TbTelemetryService>((ref) {
  return TbTelemetryService(ref.read(dioClientProvider).dio);
});

final tbWsServiceProvider = Provider<TbWebSocketService?>((ref) {
  String? token;
  ref.watch(authProvider).whenData((s) {
    if (s is AuthAuthenticated) token = s.token;
  });
  if (token == null) return null;

  final ws = TbWebSocketService(baseUrl: AppConstants.tbBaseUrl, token: token!);
  ref.onDispose(ws.dispose);
  return ws;
});

// ---------------------------------------------------------------------------
// Tile list
// ---------------------------------------------------------------------------

class DashboardTilesNotifier extends Notifier<List<DashboardTileConfig>> {
  @override
  List<DashboardTileConfig> build() => const [];

  void add(DashboardTileConfig tile) => state = [...state, tile];
  void remove(String id) => state = state.where((t) => t.id != id).toList();
  void updateTile(DashboardTileConfig updated) =>
      state = state.map((t) => t.id == updated.id ? updated : t).toList();
  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex <= oldIndex ? newIndex : newIndex - 1, item);
    state = list;
  }
}

final dashboardTilesProvider =
    NotifierProvider<DashboardTilesNotifier, List<DashboardTileConfig>>(
  DashboardTilesNotifier.new,
);

// ---------------------------------------------------------------------------
// tileDataProvider — key chỉ là tileId (String), không cần filter nữa
//
// Luồng:
//  1. HTTP fetch latest value (không có startTs/endTs) + history 2h + isOnline
//  2. Subscribe WebSocket → push realtime khi device gửi dữ liệu mới
// ---------------------------------------------------------------------------

final tileDataProvider =
    StreamProvider.family<TileData, String>((ref, tileId) async* {
  final config = ref
      .watch(dashboardTilesProvider)
      .cast<DashboardTileConfig?>()
      .firstWhere((t) => t?.id == tileId, orElse: () => null);
  if (config == null) return;

  final http = ref.read(tbTelemetryServiceProvider);
  final ws   = ref.watch(tbWsServiceProvider);

  // ── 1. Fetch ban đầu ────────────────────────────────────────────────────
  var current = await http.getTileData(config: config);
  yield current;

  if (ws == null) return;

  // ── 2. Subscribe WebSocket ───────────────────────────────────────────────
  ws.subscribeDevice(config.deviceId);

  await for (final msg in ws.messages) {
    if (msg.deviceId != config.deviceId) continue;

    final online   = msg.isOnline ?? current.isOnline;
    final newValue = msg.values[config.telemetryKey];

    var history    = current.history;
    var latest     = current.latestValue;

    if (newValue != null) {
      final pt = TelemetryPoint(time: DateTime.now(), value: newValue);
      history = [...history, pt];
      if (history.length > 50) history = history.sublist(1);
      latest = newValue;
    }

    current = TileData(
      config:      config,
      history:     history,
      latestValue: latest,
      isOnline:    online,
    );
    yield current;
  }
});

// ---------------------------------------------------------------------------
// Telemetry keys (add-tile sheet)
// ---------------------------------------------------------------------------

final deviceTelemetryKeysProvider =
    FutureProvider.family<List<String>, String>((ref, deviceId) async {
  return ref.read(tbTelemetryServiceProvider).getTelemetryKeys(deviceId);
});