import 'package:dio/dio.dart';
import 'dashboard_tile_config.dart';
import 'telemetry_model.dart';

class TbTelemetryService {
  final Dio _dio;
  TbTelemetryService(this._dio);

  /// Lấy dữ liệu cho một tile:
  ///   1. Latest value — query không có startTs/endTs → ThingsBoard trả
  ///      đúng điểm mới nhất tại thời điểm gọi (không bị lỡ dữ liệu)
  ///   2. History 2 giờ gần nhất để vẽ sparkline (30 điểm)
  ///   3. Active status từ SERVER_SCOPE attributes
  Future<TileData> getTileData({
    required DashboardTileConfig config,
  }) async {
    try {
      // ── 1. Latest value ────────────────────────────────────────────────
      // Không truyền startTs/endTs → TB trả 1 điểm mới nhất
      final latestRes = await _dio.get(
        '/api/plugins/telemetry/DEVICE/${config.deviceId}/values/timeseries',
        queryParameters: {'keys': config.telemetryKey},
      );
      final latestMap  = latestRes.data as Map<String, dynamic>;
      final latestList = latestMap[config.telemetryKey] as List<dynamic>? ?? [];
      final latestValue = latestList.isNotEmpty
          ? double.tryParse(
              (latestList.first as Map<String, dynamic>)['value'].toString())
          : null;

      // ── 2. History 2h cho sparkline ────────────────────────────────────
      final now  = DateTime.now();
      final from = now.subtract(const Duration(hours: 2));

      final histRes = await _dio.get(
        '/api/plugins/telemetry/DEVICE/${config.deviceId}/values/timeseries',
        queryParameters: {
          'keys':    config.telemetryKey,
          'startTs': from.millisecondsSinceEpoch,
          'endTs':   now.millisecondsSinceEpoch,
          'limit':   30,
          'agg':     'NONE',
        },
      );
      final histMap    = histRes.data as Map<String, dynamic>;
      final rawPoints  = histMap[config.telemetryKey] as List<dynamic>? ?? [];
      final history    = rawPoints
          .map((e) => TelemetryPoint.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      // ── 3. Active status ───────────────────────────────────────────────
      bool isOnline = false;
      try {
        final attrRes = await _dio.get(
          '/api/plugins/telemetry/DEVICE/${config.deviceId}'
          '/values/attributes/SERVER_SCOPE',
          queryParameters: {'keys': 'active'},
        );
        final attrs = attrRes.data as List<dynamic>;
        if (attrs.isNotEmpty) {
          isOnline =
              (attrs.first as Map<String, dynamic>)['value'] as bool? ?? false;
        }
      } catch (_) {}

      return TileData(
        config:       config,
        history:      history,
        // Ưu tiên latestValue từ query không có time range
        latestValue:  latestValue ?? (history.isNotEmpty ? history.last.value : null),
        isOnline:     isOnline,
      );
    } on DioException {
      return TileData(config: config, history: [], isOnline: false);
    }
  }

  Future<List<String>> getTelemetryKeys(String deviceId) async {
    try {
      final res = await _dio.get(
        '/api/plugins/telemetry/DEVICE/$deviceId/keys/timeseries',
      );
      return List<String>.from(res.data as List);
    } on DioException {
      return [];
    }
  }
}