import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../devices/devices_provider.dart';
import '../devices/device_model.dart';
import 'dashboard_tile_config.dart';
import 'dashboard_provider.dart';
import 'telemetry_model.dart';

// ===========================================================================
// MyDashboardScreen
// ===========================================================================

class MyDashboardScreen extends ConsumerWidget {
  const MyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref.watch(dashboardTilesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onAddTile: () => _showAddTileSheet(context, ref)),
            const SizedBox(height: 6),
            Expanded(
              child: tiles.isEmpty
                  ? _EmptyState(onAdd: () => _showAddTileSheet(context, ref))
                  : _TileGrid(tiles: tiles),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTileSheet(BuildContext context, WidgetRef ref) async {
    final container = ProviderScope.containerOf(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: const _AddTileSheet(),
      ),
    );
  }
}

// ===========================================================================
// Header
// ===========================================================================

class _Header extends StatelessWidget {
  final VoidCallback onAddTile;
  const _Header({required this.onAddTile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 6),
      child: Row(
        children: [
          Text(
            'My Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2B5F),
                  letterSpacing: -0.5,
                ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAddTile,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B5F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Tile grid
// ===========================================================================

class _TileGrid extends ConsumerWidget {
  final List<DashboardTileConfig> tiles;
  const _TileGrid({required this.tiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.45,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) {
        final tile      = tiles[i];
        final dataAsync = ref.watch(tileDataProvider(tile.id));

        return dataAsync.when(
          loading: () => _LoadingCard(config: tile),
          error:   (_, __) => _OfflineCard(config: tile),
          data:    (data)   => SensorCard(
            data: data,
            onLongPress: () => _confirmRemove(context, ref, tile),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, DashboardTileConfig tile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove tile'),
        content: Text('Remove "${tile.label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) ref.read(dashboardTilesProvider.notifier).remove(tile.id);
  }
}

// ===========================================================================
// Sensor card
// ===========================================================================

class SensorCard extends StatelessWidget {
  final TileData data;
  final VoidCallback? onLongPress;
  const SensorCard({super.key, required this.data, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final isOnline = data.isOnline && data.latestValue != null;
    final color    = data.config.sparklineColor;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.09),
              blurRadius: 14, offset: const Offset(0, 4)),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Title + status dot ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.config.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9BAAC8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFCDD5E0),
                    ),
                  ),
                ],
              ),
            ),

            // ── Value ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: isOnline
                  ? _ValueRow(
                      value: data.formattedValue,
                      unit: data.config.unit,
                      color: color)
                  : const _OfflineIndicator(),
            ),

            const SizedBox(height: 3),

            // ── Chart ─────────────────────────────────────────────────
            if (isOnline && data.sparklineValues.length >= 2)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                  child: CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: ChartPainter(
                      values: data.sparklineValues,
                      color:  color,
                      yMin:   data.config.yMin,
                      yMax:   data.config.yMax,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Value row
// ===========================================================================

class _ValueRow extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  const _ValueRow(
      {required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: Color(0xFF1A2B5F),
            height: 1.0,
          ),
        ),
        if (unit.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 2),
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// Offline indicator
// ===========================================================================

class _OfflineIndicator extends StatelessWidget {
  const _OfflineIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text('– –',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFCDD5E0),
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            )),
        SizedBox(width: 6),
        Icon(Icons.wifi_off_rounded, size: 11, color: Color(0xFFCDD5E0)),
      ],
    );
  }
}

// ===========================================================================
// ChartPainter — scaled Y axis + grid lines + labels + fill + glow
// ===========================================================================

class ChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double? yMin;
  final double? yMax;

  const ChartPainter({
    required this.values,
    required this.color,
    this.yMin,
    this.yMax,
  });

  // ── Khoảng cách vẽ ────────────────────────────────────────────────────────
  static const _leftPad   = 26.0;  // chỗ cho nhãn Y
  static const _rightPad  = 6.0;
  static const _topPad    = 6.0;
  static const _bottomPad = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    // ── Tính domain ─────────────────────────────────────────────────────────
    final dataMin = values.reduce(math.min);
    final dataMax = values.reduce(math.max);

    final scaleMin = yMin ?? dataMin;
    final scaleMax = yMax ?? (dataMax > dataMin ? dataMax : dataMin + 1);
    final range    = scaleMax - scaleMin;

    // Vùng vẽ thực sự (sau padding)
    final chartL = _leftPad;
    final chartT = _topPad;
    final chartR = size.width - _rightPad;
    final chartB = size.height - _bottomPad;
    final chartW = chartR - chartL;
    final chartH = chartB - chartT;

    double yFor(double v) =>
        chartT + (1 - ((v - scaleMin) / range).clamp(0.0, 1.0)) * chartH;

    double xFor(int i) =>
        chartL + (i / (values.length - 1)) * chartW;

    // ── Grid lines + nhãn Y tại 3 mức: min, mid, max ─────────────────────
    final ticks = [scaleMin, (scaleMin + scaleMax) / 2, scaleMax];
    final gridPaint = Paint()
      ..color = const Color(0xFFEDF0F7)
      ..strokeWidth = 0.7;

    for (final tick in ticks) {
      final y = yFor(tick);

      // Đường kẻ ngang nét đứt
      _drawDashed(canvas, Offset(chartL, y), Offset(chartR, y), gridPaint);

      // Nhãn bên trái
      _drawLabel(canvas, _fmtTick(tick), x: 0, y: y, color: color);
    }

    // ── Build đường line ────────────────────────────────────────────────────
    final linePath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = xFor(i);
      final y = yFor(values[i]);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        final px = xFor(i - 1);
        final py = yFor(values[i - 1]);
        final cpX = (px + x) / 2;
        linePath.cubicTo(cpX, py, cpX, y, x, y);
      }
    }

    // ── Gradient fill ────────────────────────────────────────────────────────
    final fillPath = Path()
      ..addPath(linePath, Offset.zero)
      ..lineTo(chartR, chartB)
      ..lineTo(chartL, chartB)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, chartT),
          Offset(0, chartB),
          [color.withOpacity(0.20), color.withOpacity(0.0)],
        )
        ..style = PaintingStyle.fill,
    );

    // ── Glow ─────────────────────────────────────────────────────────────────
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color.withOpacity(0.20)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── Line ─────────────────────────────────────────────────────────────────
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Dot cuối: vòng trắng + chấm màu + vòng mờ ────────────────────────
    final lx = xFor(values.length - 1);
    final ly = yFor(values.last);
    canvas.drawCircle(Offset(lx, ly), 5.0,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(lx, ly), 3.2,
        Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(lx, ly),
        5.0,
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 3.0;
    const gap  = 2.5;
    final total = end.dx - start.dx;
    for (double x = 0; x < total; x += dash + gap) {
      canvas.drawLine(
        Offset(start.dx + x, start.dy),
        Offset(start.dx + math.min(x + dash, total), start.dy),
        paint,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text,
      {required double x, required double y, required Color color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 7,
          color: color.withOpacity(0.55),
          fontWeight: FontWeight.w600,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: _leftPad - 3);

    tp.paint(
      canvas,
      Offset(x + (_leftPad - 3 - tp.width), y - tp.height / 2),
    );
  }

  String _fmtTick(double v) {
    if (v >= 1000)  return '${(v / 1000).toStringAsFixed(1)}k';
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(ChartPainter old) =>
      old.values != values ||
      old.color  != color  ||
      old.yMin   != yMin   ||
      old.yMax   != yMax;
}

// ===========================================================================
// Loading / Offline cards
// ===========================================================================

class _LoadingCard extends StatelessWidget {
  final DashboardTileConfig config;
  const _LoadingCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(config.label,
            style:
                const TextStyle(fontSize: 11.5, color: Color(0xFF9BAAC8))),
        const SizedBox(height: 10),
        SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: config.sparklineColor),
        ),
      ]),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  final DashboardTileConfig config;
  const _OfflineCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(config.label,
                style: const TextStyle(
                    fontSize: 11.5, color: Color(0xFF9BAAC8))),
          ),
          Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFCDD5E0)),
          ),
        ]),
        const SizedBox(height: 6),
        const _OfflineIndicator(),
      ]),
    );
  }
}

// ===========================================================================
// Empty state
// ===========================================================================

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dashboard_customize_outlined,
              size: 52, color: Color(0xFFCDD5E0)),
          const SizedBox(height: 14),
          const Text('No tiles yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2B5F))),
          const SizedBox(height: 6),
          const Text('Tap + to add a sensor tile',
              style: TextStyle(fontSize: 12, color: Color(0xFF9BAAC8))),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add tile'),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Add-tile bottom sheet
// ===========================================================================

class _AddTileSheet extends ConsumerStatefulWidget {
  const _AddTileSheet({super.key});
  @override
  ConsumerState<_AddTileSheet> createState() => _AddTileSheetState();
}

class _AddTileSheetState extends ConsumerState<_AddTileSheet> {
  Device? _selectedDevice;
  String? _selectedKey;
  Color   _selectedColor = DashboardTileConfig.presetColors.first;

  final _labelCtrl = TextEditingController();
  final _unitCtrl  = TextEditingController();
  final _yMinCtrl  = TextEditingController();
  final _yMaxCtrl  = TextEditingController();

  @override
  void dispose() {
    _labelCtrl.dispose();
    _unitCtrl.dispose();
    _yMinCtrl.dispose();
    _yMaxCtrl.dispose();
    super.dispose();
  }

  // Khi chọn key → thử tự điền range
  void _onKeySelected(String k) {
    setState(() {
      _selectedKey = k;
      if (_labelCtrl.text.isEmpty ||
          _labelCtrl.text == _selectedDevice!.name) {
        _labelCtrl.text = k;
      }
    });
    final auto = DashboardTileConfig.autoRange(k);
    if (auto != null) {
      _yMinCtrl.text = _fmt(auto.yMin);
      _yMaxCtrl.text = _fmt(auto.yMax);
    }
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Tile',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            const _Label('Device'),
            const SizedBox(height: 8),
            _DevicePicker(
              selected: _selectedDevice,
              onSelected: (d) => setState(() {
                _selectedDevice = d;
                _selectedKey = null;
                _yMinCtrl.clear();
                _yMaxCtrl.clear();
                if (_labelCtrl.text.isEmpty) _labelCtrl.text = d.name;
              }),
            ),
            const SizedBox(height: 16),

            if (_selectedDevice != null) ...[
              const _Label('Telemetry Key'),
              const SizedBox(height: 8),
              _KeyPicker(
                deviceId: _selectedDevice!.id,
                selected: _selectedKey,
                onSelected: _onKeySelected,
              ),
              const SizedBox(height: 16),
            ],

            const _Label('Display Name'),
            const SizedBox(height: 8),
            _SheetTextField(controller: _labelCtrl, hint: 'e.g. Temperature'),
            const SizedBox(height: 12),

            const _Label('Unit'),
            const SizedBox(height: 8),
            _SheetTextField(controller: _unitCtrl, hint: 'e.g. °C or %'),
            const SizedBox(height: 14),

            // ── Y axis range ──────────────────────────────────────────────
            const _Label('Chart range (Y axis)'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _SheetTextField(
                  controller: _yMinCtrl,
                  hint: 'Min  e.g. 0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('–',
                    style: TextStyle(color: Color(0xFF9BAAC8), fontSize: 16)),
              ),
              Expanded(
                child: _SheetTextField(
                  controller: _yMaxCtrl,
                  hint: 'Max  e.g. 100',
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              _selectedKey != null &&
                      DashboardTileConfig.autoRange(_selectedKey!) != null
                  ? '✦ Tự động nhận diện từ key "$_selectedKey"'
                  : 'Để trống → tự scale theo data',
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF9BAAC8),
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 14),

            const _Label('Colour'),
            const SizedBox(height: 8),
            _ColorPicker(
              selected: _selectedColor,
              onSelected: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Tile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _selectedDevice != null &&
      _selectedKey != null &&
      _labelCtrl.text.trim().isNotEmpty;

  void _submit() {
    final tile = DashboardTileConfig(
      id: '${_selectedDevice!.id}_${_selectedKey}_'
          '${DateTime.now().millisecondsSinceEpoch}',
      label:         _labelCtrl.text.trim(),
      deviceId:      _selectedDevice!.id,
      deviceName:    _selectedDevice!.name,
      telemetryKey:  _selectedKey!,
      unit:          _unitCtrl.text.trim(),
      sparklineColor: _selectedColor,
      yMin: double.tryParse(_yMinCtrl.text.trim()),
      yMax: double.tryParse(_yMaxCtrl.text.trim()),
    );
    ref.read(dashboardTilesProvider.notifier).add(tile);
    Navigator.pop(context);
  }
}

// ===========================================================================
// Sheet sub-widgets
// ===========================================================================

class _DevicePicker extends ConsumerWidget {
  final Device? selected;
  final ValueChanged<Device> onSelected;
  const _DevicePicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(devicesProvider).when(
      loading: () => const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Could not load devices',
          style: TextStyle(
              color: Theme.of(context).colorScheme.error, fontSize: 12)),
      data: (devices) {
        if (devices.isEmpty)
          return const Text('No devices found',
              style: TextStyle(color: Color(0xFF9BAAC8)));
        return Wrap(
          spacing: 8, runSpacing: 8,
          children: devices
              .map((d) => ChoiceChip(
                    label: Text(d.name),
                    selected: d.id == selected?.id,
                    onSelected: (_) => onSelected(d),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _KeyPicker extends ConsumerWidget {
  final String deviceId;
  final String? selected;
  final ValueChanged<String> onSelected;
  const _KeyPicker(
      {required this.deviceId,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(deviceTelemetryKeysProvider(deviceId)).when(
      loading: () => const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Text('Could not load keys',
          style: TextStyle(color: Colors.red, fontSize: 12)),
      data: (keys) {
        if (keys.isEmpty)
          return const Text('No telemetry data available',
              style: TextStyle(color: Color(0xFF9BAAC8)));
        return Wrap(
          spacing: 8, runSpacing: 8,
          children: keys
              .map((k) => ChoiceChip(
                    label: Text(k),
                    selected: k == selected,
                    onSelected: (_) => onSelected(k),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;
  const _ColorPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DashboardTileConfig.presetColors.map((c) {
        final isSel = c.value == selected.value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: c, shape: BoxShape.circle,
                border: isSel
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
                boxShadow: isSel
                    ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                    : null,
              ),
              child: isSel
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7CB0),
          letterSpacing: 0.4));
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _SheetTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBCC5D6)),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      );
}