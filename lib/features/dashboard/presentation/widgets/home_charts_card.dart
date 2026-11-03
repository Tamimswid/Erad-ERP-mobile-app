import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/core/widgets/app_period_selector.dart';
import 'package:erad/core/widgets/app_section_header.dart';
import 'package:erad/core/widgets/charts/app_area_chart.dart';
import 'package:erad/core/widgets/charts/app_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../data/mock/dashboard_mock_data.dart';

class HomeChartsCard extends StatefulWidget {
  const HomeChartsCard({super.key});

  @override
  State<HomeChartsCard> createState() => _HomeChartsCardState();
}

class _HomeChartsCardState extends State<HomeChartsCard> {
  HomeChartRange _range = HomeChartRange.month;

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;
    final earnings = DashboardMockData.earnings(_range);
    final sales = DashboardMockData.productSales(_range);

    return sc.Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'الأداء'),
          const SizedBox(height: 12),
          AppPeriodSelector<HomeChartRange>(
            expanded: true,
            options: const [
              AppPeriodOption(value: HomeChartRange.month, label: 'شهري'),
              AppPeriodOption(value: HomeChartRange.year, label: 'سنوي'),
            ],
            selected: _range,
            onChanged: (range) => setState(() => _range = range),
          ),
          const SizedBox(height: 20),
          _ChartHeader(
            title: 'الأرباح',
            value: NumberFormatter.formatShort(earnings.total),
          ),
          const SizedBox(height: 8),
          AppAreaChart(data: earnings, color: scheme.chart2, height: 140),
          const SizedBox(height: 12),
          sc.Divider(color: scheme.border, height: 1),
          const SizedBox(height: 12),
          _ChartHeader(
            title: 'مبيعات المنتجات',
            value: '${sales.total.toInt()} قطعة',
          ),
          const SizedBox(height: 8),
          AppBarChart(data: sales, color: scheme.chart1, height: 140),
        ],
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  final String title;
  final String value;

  const _ChartHeader({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.foreground,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
        ),
      ],
    );
  }
}
