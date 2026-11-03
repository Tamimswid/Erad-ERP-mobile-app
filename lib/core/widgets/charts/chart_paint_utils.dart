import 'dart:math' as math;

import 'package:erad/core/theme/shadcn_theme.dart';
import 'package:flutter/material.dart';

class ChartAxis {
  ChartAxis._();

  static const EdgeInsets padding = EdgeInsets.only(
    left: 38,
    right: 6,
    top: 10,
    bottom: 22,
  );

  static Rect plot(Size size) {
    return Rect.fromLTRB(
      padding.left,
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom,
    );
  }

  static double niceMax(double maxValue) {
    if (maxValue <= 0) return 1;
    const divisions = 3;
    final rawStep = maxValue / divisions;
    final magnitude = math
        .pow(10, (math.log(rawStep) / math.ln10).floor())
        .toDouble();
    final normalized = rawStep / magnitude;
    final niceStep = normalized <= 1
        ? 1.0
        : normalized <= 2
        ? 2.0
        : normalized <= 2.5
        ? 2.5
        : normalized <= 5
        ? 5.0
        : 10.0;
    return niceStep * magnitude * divisions;
  }

  static String compact(double value) {
    if (value >= 1000000000) return '${_trim(value / 1000000000)}B';
    if (value >= 1000000) return '${_trim(value / 1000000)}M';
    if (value >= 1000) return '${_trim(value / 1000)}K';
    return _trim(value);
  }

  static String _trim(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static void drawGrid({
    required Canvas canvas,
    required Rect plot,
    required double maxValue,
    required Color gridColor,
    required Color labelColor,
  }) {
    const divisions = 3;
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= divisions; i++) {
      final y = plot.bottom - plot.height * i / divisions;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), paint);

      final value = maxValue * i / divisions;
      final label = text(
        compact(value),
        TextStyle(fontSize: 10, color: labelColor),
        TextDirection.ltr,
      );
      label.paint(
        canvas,
        Offset(plot.left - label.width - 6, y - label.height / 2),
      );
    }
  }

  static void drawLabels({
    required Canvas canvas,
    required Rect plot,
    required List<String> labels,
    required Color color,
    required TextDirection textDirection,
    bool slotCentered = false,
  }) {
    if (labels.isEmpty) return;

    final maxLabels = math.max(1, plot.width ~/ 44);
    final step = math.max(1, (labels.length / maxLabels).ceil());

    var lastDrawn = -1;
    for (var i = 0; i < labels.length; i += step) {
      _drawLabel(canvas, plot, labels, i, color, textDirection, slotCentered);
      lastDrawn = i;
    }

    final last = labels.length - 1;
    if (last - lastDrawn >= step) {
      _drawLabel(
        canvas,
        plot,
        labels,
        last,
        color,
        textDirection,
        slotCentered,
      );
    }
  }

  static void _drawLabel(
    Canvas canvas,
    Rect plot,
    List<String> labels,
    int index,
    Color color,
    TextDirection textDirection,
    bool slotCentered,
  ) {
    final double x;
    if (labels.length == 1) {
      x = plot.center.dx;
    } else if (slotCentered) {
      x = plot.left + plot.width * (index + 0.5) / labels.length;
    } else {
      x = plot.left + plot.width * index / (labels.length - 1);
    }

    final label = text(
      labels[index],
      TextStyle(fontSize: 10, color: color),
      textDirection,
    );
    label.paint(canvas, Offset(x - label.width / 2, plot.bottom + 8));
  }

  static TextPainter text(
    String value,
    TextStyle style,
    TextDirection textDirection,
  ) {
    return TextPainter(
      text: TextSpan(
        text: value,
        style: style.copyWith(fontFamily: AppShadcnTheme.fontFamily),
      ),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
  }
}
