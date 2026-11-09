import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/core/widgets/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../data/models/dashboard_daily_summary.dart';
import '../../data/models/dashboard_period.dart';
import '../bloc/dashboard_cubit.dart';

class HomeChartsCard extends StatelessWidget {
  final DashboardLoaded state;

  const HomeChartsCard({super.key, required this.state});

  static final NumberFormat _countFormat = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;
    final buckets = _buildBuckets(state);
    final summary = state.dailySummary;

    final totalRevenue = summary.fold<double>(
      0,
      (sum, d) => sum + d.salesRevenue,
    );
    final totalQuantity = summary.fold<int>(
      0,
      (sum, d) => sum + d.salesQuantity,
    );
    final totalInvoices = summary.fold<int>(
      0,
      (sum, d) => sum + d.invoiceCount,
    );

    return sc.Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'المبيعات',
            subtitle: 'حسب الفترة المحددة',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Metric(
                  label: 'إجمالي المبيعات',
                  value: NumberFormatter.formatShort(totalRevenue),
                  emphasized: true,
                ),
              ),
              _Metric(
                label: 'القطع المباعة',
                value: _countFormat.format(totalQuantity),
              ),
              const SizedBox(width: 20),
              _Metric(
                label: 'الفواتير',
                value: _countFormat.format(totalInvoices),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (buckets.isEmpty || totalRevenue <= 0)
            _EmptyChart(color: scheme.mutedForeground)
          else ...[
            _SimpleBars(buckets: buckets, color: scheme.primary),
            const SizedBox(height: 8),
            _BarLabels(buckets: buckets),
          ],
        ],
      ),
    );
  }

  List<_ChartBucket> _buildBuckets(DashboardLoaded state) {
    switch (state.period) {
      case DashboardPeriod.year:
        final year = int.tryParse(state.selectedYear) ?? DateTime.now().year;
        return List.generate(12, (index) {
          final start = DateTime(year, index + 1, 1);
          final end = DateTime(year, index + 2, 0);
          return _ChartBucket(
            '${index + 1}',
            _sumRange(state.dailySummary, start, end),
          );
        });
      case DashboardPeriod.month:
        final start = DateTime(
          state.selectedMonth.year,
          state.selectedMonth.month,
          1,
        );
        final end = DateTime(
          state.selectedMonth.year,
          state.selectedMonth.month + 1,
          0,
        );
        return _weekBuckets(state.dailySummary, start, end);
      case DashboardPeriod.custom:
        final range = state.customDateRange;
        if (range == null) return const [];
        return _customBuckets(state.dailySummary, range.start, range.end);
    }
  }

  List<_ChartBucket> _weekBuckets(
    List<DashboardDailySummaryModel> summary,
    DateTime start,
    DateTime end,
  ) {
    final buckets = <_ChartBucket>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      final weekEnd = cursor.add(const Duration(days: 6));
      final bucketEnd = weekEnd.isAfter(end) ? end : weekEnd;
      buckets.add(
        _ChartBucket('${cursor.day}', _sumRange(summary, cursor, bucketEnd)),
      );
      cursor = bucketEnd.add(const Duration(days: 1));
    }
    return buckets;
  }

  List<_ChartBucket> _customBuckets(
    List<DashboardDailySummaryModel> summary,
    DateTime start,
    DateTime end,
  ) {
    final totalDays = end.difference(start).inDays + 1;
    final bucketCount = totalDays < 6 ? totalDays : 6;
    final bucketSize = (totalDays / bucketCount).ceil();

    final buckets = <_ChartBucket>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      var bucketEnd = cursor.add(Duration(days: bucketSize - 1));
      if (bucketEnd.isAfter(end)) bucketEnd = end;
      buckets.add(
        _ChartBucket(
          '${cursor.day}/${cursor.month}',
          _sumRange(summary, cursor, bucketEnd),
        ),
      );
      cursor = bucketEnd.add(const Duration(days: 1));
    }
    return buckets;
  }

  double _sumRange(
    List<DashboardDailySummaryModel> summary,
    DateTime start,
    DateTime end,
  ) {
    var total = 0.0;
    for (final day in summary) {
      if (day.day.isBefore(start)) continue;
      if (day.day.isAfter(end)) continue;
      total += day.salesRevenue;
    }
    return total;
  }
}

class _ChartBucket {
  final String label;
  final double value;

  const _ChartBucket(this.label, this.value);
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _Metric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: scheme.mutedForeground),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 22 : 15,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
            color: scheme.foreground,
          ),
        ),
      ],
    );
  }
}

class _SimpleBars extends StatelessWidget {
  static const double _height = 110;

  final List<_ChartBucket> buckets;
  final Color color;

  const _SimpleBars({required this.buckets, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;
    final maxValue = buckets.fold<double>(
      0,
      (max, bucket) => bucket.value > max ? bucket.value : max,
    );

    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bucket in buckets)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: bucket.value <= 0
                        ? 3
                        : (bucket.value / maxValue * _height)
                              .clamp(6, _height)
                              .toDouble(),
                    decoration: BoxDecoration(
                      color: bucket.value <= 0
                          ? scheme.mutedForeground.withValues(alpha: 0.15)
                          : color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarLabels extends StatelessWidget {
  final List<_ChartBucket> buckets;

  const _BarLabels({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Row(
      children: [
        for (final bucket in buckets)
          Expanded(
            child: Text(
              bucket.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(fontSize: 10, color: scheme.mutedForeground),
            ),
          ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final Color color;

  const _EmptyChart({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: Text(
        'لا توجد مبيعات في هذه الفترة',
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}
