import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Tile config
// ---------------------------------------------------------------------------

class DashboardTileConfig {
  final String id;
  final String label;
  final String deviceId;
  final String deviceName;
  final String telemetryKey;
  final String unit;
  final Color sparklineColor;

  /// Giới hạn trục Y — nếu null thì auto từ data
  final double? yMin;
  final double? yMax;

  const DashboardTileConfig({
    required this.id,
    required this.label,
    required this.deviceId,
    required this.deviceName,
    required this.telemetryKey,
    this.unit = '',
    this.sparklineColor = const Color(0xFF26C6DA),
    this.yMin,
    this.yMax,
  });

  // ── Màu preset ────────────────────────────────────────────────────────────

  static const List<Color> presetColors = [
    Color(0xFF26C6DA),
    Color(0xFFEF5350),
    Color(0xFFFFCA28),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
  ];

  // ── Tự động nhận diện dải giá trị theo tên key ────────────────────────────
  //
  //  Trả về (yMin, yMax) gợi ý — người dùng vẫn override được.
  //  Dùng khi thêm tile mới để điền sẵn giá trị hợp lý.

  static ({double yMin, double yMax})? autoRange(String key) {
    final k = key.toLowerCase();
    if (k.contains('temp'))                         return (yMin: 0,   yMax: 80);
    if (k.contains('humid') || k.contains('moist')) return (yMin: 0,   yMax: 100);
    if (k.contains('pressure'))                     return (yMin: 900, yMax: 1100);
    if (k.contains('co2'))                          return (yMin: 400, yMax: 2000);
    if (k.contains('pm25') || k.contains('pm2_5')) return (yMin: 0,   yMax: 500);
    if (k.contains('light') || k.contains('lux'))  return (yMin: 0,   yMax: 1000);
    if (k.contains('battery') || k.contains('soc')) return (yMin: 0,  yMax: 100);
    if (k.contains('voltage'))                      return (yMin: 0,   yMax: 5);
    if (k.contains('current'))                      return (yMin: 0,   yMax: 20);
    if (k.contains('speed') || k.contains('wind')) return (yMin: 0,   yMax: 100);
    return null;
  }

  DashboardTileConfig copyWith({
    String? label,
    String? unit,
    Color? sparklineColor,
    double? yMin,
    double? yMax,
  }) =>
      DashboardTileConfig(
        id: id,
        label: label ?? this.label,
        deviceId: deviceId,
        deviceName: deviceName,
        telemetryKey: telemetryKey,
        unit: unit ?? this.unit,
        sparklineColor: sparklineColor ?? this.sparklineColor,
        yMin: yMin ?? this.yMin,
        yMax: yMax ?? this.yMax,
      );
}