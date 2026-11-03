import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import 'app_chart_data.dart';
import 'chart_paint_utils.dart';

class AppAreaChart extends StatelessWidget {
  final AppChartData data;
  final Color color;
  final double height;

  const AppAreaChart({
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
        painter: _AreaChartPainter(
          data: data,
          color: color,
          gridColor: scheme.border,
          labelColor: scheme.mutedForeground,
          dotColor: scheme.background,
          textDirection: Directionality.of(context),
        ),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final AppChartData data;
  final Color color;
  final Color gridColor;
  final Color labelColor;
  final Color dotColor;
  final TextDirection textDirection;

  _AreaChartPainter({
    required this.data,
    required this.color,
    required this.gridColor,
    required this.labelColor,
    required this.dotColor,
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
    );

    if (data.isEmpty) return;

    final points = <Offset>[
      for (var i = 0; i < data.values.length; i++)
        Offset(
          data.values.length == 1
              ? plot.center.dx
              : plot.left + plot.width * i / (data.values.length - 1),
          plot.bottom - plot.height * (data.values[i] / maxValue).clamp(0, 1),
        ),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final middleX = current.dx + (next.dx - current.dx) / 2;
      line.cubicTo(middleX, current.dy, middleX, next.dy, next.dx, next.dy);
    }

    final fill = Path.from(line)
      ..lineTo(points.last.dx, plot.bottom)
      ..lineTo(points.first.dx, plot.bottom)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(plot),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (points.length <= 12) {
      for (final point in points) {
        canvas.drawCircle(point, 3, Paint()..color = color);
        canvas.drawCircle(
          point,
          3,
          Paint()
            ..color = dotColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}
