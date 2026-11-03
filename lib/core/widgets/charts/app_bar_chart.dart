import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import 'app_chart_data.dart';
import 'chart_paint_utils.dart';

class AppBarChart extends StatelessWidget {
  final AppChartData data;
  final Color color;
  final double height;

  const AppBarChart({
    super.key,
    required this.data,
    required this.color,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _BarChartPainter(
          data: data,
          color: color,
          gridColor: scheme.border,
          labelColor: scheme.mutedForeground,
          textDirection: Directionality.of(context),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final AppChartData data;
  final Color color;
  final Color gridColor;
  final Color labelColor;
  final TextDirection textDirection;

  _BarChartPainter({
    required this.data,
    required this.color,
    required this.gridColor,
    required this.labelColor,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plot = ChartAxis.plot(size);
    final maxValue = ChartAxis.niceMax(data.maxValue);

    ChartAxis.drawGrid(
      canvas: canvas,
      plot: plot,
      maxValue: maxValue,
      gridColor: gridColor,
      labelColor: labelColor,
    );
    ChartAxis.drawLabels(
      canvas: canvas,
      plot: plot,
      labels: data.labels,
      color: labelColor,
      textDirection: textDirection,
      slotCentered: true,
    );

    if (data.isEmpty) return;

    final slotWidth = plot.width / data.values.length;
    final barWidth = (slotWidth * 0.55).clamp(4.0, 22.0);
    final peak = data.maxValue;

    for (var i = 0; i < data.values.length; i++) {
      final value = data.values[i];
      final barHeight = plot.height * (value / maxValue).clamp(0, 1);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          plot.left + slotWidth * i + (slotWidth - barWidth) / 2,
          plot.bottom - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(4),
      );
      final isPeak = peak > 0 && value == peak;
      canvas.drawRRect(
        rect,
        Paint()..color = color.withValues(alpha: isPeak ? 1 : 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}
