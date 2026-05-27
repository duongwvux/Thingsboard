import 'dashboard_tile_config.dart';

// ---------------------------------------------------------------------------
// TelemetryPoint — one data point from ThingsBoard
// ---------------------------------------------------------------------------

class TelemetryPoint {
  final DateTime time;
  final double value;

  const TelemetryPoint({required this.time, required this.value});

  factory TelemetryPoint.fromJson(Map<String, dynamic> json) => TelemetryPoint(
        time: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        value: double.tryParse(json['value'].toString()) ?? 0.0,
      );
}

// ---------------------------------------------------------------------------
// TileData — resolved data for one sensor card
// ---------------------------------------------------------------------------

class TileData {
  final DashboardTileConfig config;
  final List<TelemetryPoint> history;
  final double? latestValue;
  final bool isOnline;

  const TileData({
    required this.config,
    required this.history,
    this.latestValue,
    this.isOnline = false,
  });

  /// Integer if whole number, one decimal otherwise
  String get formattedValue {
    if (latestValue == null) return '--';
    if (latestValue! % 1 == 0) return latestValue!.toInt().toString();
    return latestValue!.toStringAsFixed(1);
  }

  /// Flat list of values for the sparkline painter
  List<double> get sparklineValues => history.map((p) => p.value).toList();
}