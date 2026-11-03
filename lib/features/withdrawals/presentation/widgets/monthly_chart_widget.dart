import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';

class MonthlyChartWidget extends StatelessWidget {
  final List<double> monthlyData;

  const MonthlyChartWidget({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    final values = monthlyData;
    final isEmpty = values.isEmpty || values.every((v) => v == 0);

    if (isEmpty) {
      return sc.Card(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'لا توجد بيانات للعرض',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxY = _calculateMaxY(values);

    return sc.Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'السحوبات الشهرية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${NumberFormatter.format(rod.toY)}',
                        const TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index > 11) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            (index + 1).toString(),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 25,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        final formatted = _formatCompactNumber(value);
                        return Text(
                          formatted,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                barGroups: List.generate(12, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        color: AppColors.primary,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: values[index] > 0 ? [0] : [],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<double> values) {
    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue * 1.2 : 100;
  }

  String _formatCompactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}