import 'dart:math' show max;
import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class ChartCategory {
  final String id;
  final String name;
  final List<double> monthlyValues;
  final Color lineColor;
  final Color fillColor;

  ChartCategory({
    required this.id,
    required this.name,
    required this.monthlyValues,
    required this.lineColor,
    Color? fillColor,
  }) : fillColor = fillColor ?? lineColor.withOpacity(0.15),
       assert(
         monthlyValues.length == 12,
         'يجب أن تحتوي القيم الشهرية على 12 عنصرًا',
       );
}

class ChartPoint {
  final String categoryId;
  final String categoryName;
  final int monthIndex;
  final String monthName;
  final double value;

  ChartPoint({
    required this.categoryId,
    required this.categoryName,
    required this.monthIndex,
    required this.monthName,
    required this.value,
  });
}

class FinancialAreaChart extends StatefulWidget {
  final List<ChartCategory> categories;
  final String? title;
  final bool showFilterButtons;
  final bool showLegend;
  final double height;
  final EdgeInsets padding;
  final ValueChanged<ChartCategory>? onCategoryToggle;
  final ValueChanged<ChartPoint>? onPointTap;

  const FinancialAreaChart({
    super.key,
    required this.categories,
    this.title,
    this.showFilterButtons = true,
    this.showLegend = true,
    this.height = 320,
    this.padding = const EdgeInsets.all(20),
    this.onCategoryToggle,
    this.onPointTap,
  });

  @override
  State<FinancialAreaChart> createState() => _FinancialAreaChartState();
}

class _FinancialAreaChartState extends State<FinancialAreaChart> {
  late Set<String> _visibleCategories;

  @override
  void initState() {
    super.initState();
    _visibleCategories = widget.categories.map((c) => c.id).toSet();
  }

  @override
  void didUpdateWidget(covariant FinancialAreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIds = widget.categories.map((c) => c.id).toSet();
    _visibleCategories = _visibleCategories.intersection(newIds);
    _visibleCategories.addAll(newIds);
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_visibleCategories.contains(categoryId)) {
        if (_visibleCategories.length > 1) {
          _visibleCategories.remove(categoryId);
        }
      } else {
        _visibleCategories.add(categoryId);
      }
    });
    final category = widget.categories.firstWhere((c) => c.id == categoryId);
    widget.onCategoryToggle?.call(category);
  }

  void _showAll() {
    setState(() {
      _visibleCategories = widget.categories.map((c) => c.id).toSet();
    });
  }

  List<ChartCategory> get _visibleList {
    return widget.categories
        .where((c) => _visibleCategories.contains(c.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null || widget.showFilterButtons)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
                const Spacer(),
                if (widget.showFilterButtons && widget.categories.length > 1)
                  _buildFilterButtons(),
              ],
            ),
          ),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: widget.height,
                minWidth: 600, // Minimum width for proper chart display
              ),
              child: SizedBox(
                height: widget.height,
                width: 600, // Fixed width for chart
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _AreaChartPainter(categories: visible),
                ),
              ),
            ),
          ),
        ),
        if (widget.showLegend && visible.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildLegend(visible),
          ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    final allButtons = <Widget>[
      _FilterButton(
        label: 'الجميع',
        isActive: _visibleCategories.length == widget.categories.length,
        onTap: _showAll,
      ),
      ...widget.categories.map(
        (c) => _FilterButton(
          label: c.name,
          isActive: _visibleCategories.contains(c.id),
          color: _visibleCategories.contains(c.id) ? c.lineColor : null,
          onTap: () => _toggleCategory(c.id),
        ),
      ),
    ];

    final midPoint = (allButtons.length / 2).ceil();
    final firstRow = allButtons.take(midPoint).toList();
    final secondRow = allButtons.skip(midPoint).toList();

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: firstRow.map((button) => Padding(
              padding: const EdgeInsets.only(left: 10),
              child: button,
            )).toList(),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: secondRow.map((button) => Padding(
              padding: const EdgeInsets.only(left: 10),
              child: button,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<ChartCategory> list) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: list
          .map(
            (c) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c.lineColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          border: Border.all(
            color: isActive ? AppColors.accent : const Color(0xFFE0E0E0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<ChartCategory> categories;
  _AreaChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;

    final pad = const EdgeInsets.only(left: 50, right: 20, top: 30, bottom: 40);
    final cw = size.width - pad.left - pad.right;
    final ch = size.height - pad.top - pad.bottom;

    double maxVal = 0;
    for (final c in categories) {
      for (final v in c.monthlyValues) {
        maxVal = max(maxVal, v);
      }
    }
    maxVal = ((maxVal ~/ 10000) + 1) * 10000;
    if (maxVal == 0) maxVal = 100000;

    _drawGrid(canvas, size, pad, cw, ch, maxVal);

    for (final cat in categories) {
      _drawArea(canvas, pad, cw, ch, maxVal, cat);
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    EdgeInsets p,
    double cw,
    double ch,
    double maxVal,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const style = TextStyle(fontSize: 11, color: Color(0xFF999999));

    for (int i = 0; i <= 5; i++) {
      final y = p.top + ch - (i * ch / 5);
      final val = (maxVal * i / 5);
      canvas.drawLine(
        Offset(p.left, y),
        Offset(p.left + cw, y),
        paint..strokeWidth = i == 0 ? 1.5 : 1,
      );

      final text = i == 0 ? '₺0' : '₺${(val / 1000).toStringAsFixed(0)}K';
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.left - tp.width - 8, y - tp.height / 2));
    }

    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    for (int i = 0; i < 12; i++) {
      final x = p.left + (i * cw / 11);
      final tp = TextPainter(
        text: TextSpan(text: months[i], style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, p.top + ch + 10));
    }
  }

  void _drawArea(
    Canvas canvas,
    EdgeInsets p,
    double cw,
    double ch,
    double maxVal,
    ChartCategory cat,
  ) {
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < 12; i++) {
      final x = p.left + (i * cw / 11);
      final value = cat.monthlyValues[i] > 0 ? cat.monthlyValues[i] : 0;
      final y = p.top + ch - ((value / maxVal) * ch);
      points.add(Offset(x, y));
    }

    // Smooth curve with cubic bezier
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // Close path for fill
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, p.top + ch);
    fillPath.lineTo(points.first.dx, p.top + ch);
    fillPath.close();

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cat.fillColor.withOpacity(0.6),
          cat.fillColor.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTRB(p.left, p.top, p.left + cw, p.top + ch))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = cat.lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
