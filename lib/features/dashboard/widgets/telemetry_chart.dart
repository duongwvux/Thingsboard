import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TelemetryChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double? yMin;
  final double? yMax;

  const TelemetryChart({
    super.key,
    required this.values,
    required this.color,
    this.yMin,
    this.yMax,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      child: CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: _TelemetryChartPainter(
          values: values,
          color: color,
          yMin: yMin,
          yMax: yMax,
        ),
      ),
    );
  }
}

class _TelemetryChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double? yMin;
  final double? yMax;

  const _TelemetryChartPainter({
    required this.values,
    required this.color,
    this.yMin,
    this.yMax,
  });

  static const _leftPad = 26.0;
  static const _rightPad = 6.0;
  static const _topPad = 6.0;
  static const _bottomPad = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final dataMin = values.reduce(math.min);
    final dataMax = values.reduce(math.max);
    final scaleMin = yMin ?? dataMin;
    final requestedMax = yMax ?? (dataMax > dataMin ? dataMax : dataMin + 1);
    final scaleMax = requestedMax > scaleMin ? requestedMax : scaleMin + 1;
    final range = scaleMax - scaleMin;

    final chartLeft = _leftPad;
    final chartTop = _topPad;
    final chartRight = size.width - _rightPad;
    final chartBottom = size.height - _bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    double yFor(double value) {
      return chartTop +
          (1 - ((value - scaleMin) / range).clamp(0.0, 1.0)) * chartHeight;
    }

    double xFor(int index) {
      return chartLeft + (index / (values.length - 1)) * chartWidth;
    }

    final ticks = [scaleMin, (scaleMin + scaleMax) / 2, scaleMax];
    final gridPaint = Paint()
      ..color = AppColors.dashboardGrid
      ..strokeWidth = 0.7;

    for (final tick in ticks) {
      final y = yFor(tick);
      _drawDashed(
        canvas,
        Offset(chartLeft, y),
        Offset(chartRight, y),
        gridPaint,
      );
      _drawLabel(canvas, _formatTick(tick), x: 0, y: y);
    }

    final linePath = Path();
    for (var index = 0; index < values.length; index++) {
      final x = xFor(index);
      final y = yFor(values[index]);
      if (index == 0) {
        linePath.moveTo(x, y);
      } else {
        final previousX = xFor(index - 1);
        final previousY = yFor(values[index - 1]);
        final controlX = (previousX + x) / 2;
        linePath.cubicTo(controlX, previousY, controlX, y, x, y);
      }
    }

    final fillPath = Path()
      ..addPath(linePath, Offset.zero)
      ..lineTo(chartRight, chartBottom)
      ..lineTo(chartLeft, chartBottom)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, chartTop),
          Offset(0, chartBottom),
          [color.withValues(alpha: 0.20), color.withValues(alpha: 0)],
        )
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color.withValues(alpha: 0.20)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastX = xFor(values.length - 1);
    final lastY = yFor(values.last);
    canvas.drawCircle(
      Offset(lastX, lastY),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      3.2,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      5,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 3.0;
    const gap = 2.5;
    final total = end.dx - start.dx;
    for (var x = 0.0; x < total; x += dash + gap) {
      canvas.drawLine(
        Offset(start.dx + x, start.dy),
        Offset(start.dx + math.min(x + dash, total), start.dy),
        paint,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text, {
    required double x,
    required double y,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 7,
          color: color.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: _leftPad - 3);

    painter.paint(
      canvas,
      Offset(x + (_leftPad - 3 - painter.width), y - painter.height / 2),
    );
  }

  String _formatTick(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(_TelemetryChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.yMin != yMin ||
        oldDelegate.yMax != yMax;
  }
}
