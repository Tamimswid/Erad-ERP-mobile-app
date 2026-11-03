import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/core/widgets/app_period_selector.dart';
import 'package:erad/core/widgets/app_section_header.dart';
import 'package:erad/core/widgets/app_stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../data/models/dashboard_period.dart';
import '../bloc/dashboard_cubit.dart';

class HomeSummaryCard extends StatelessWidget {
  final DashboardLoaded state;

  const HomeSummaryCard({super.key, required this.state});

  String get _rangeLabel {
    switch (state.period) {
      case DashboardPeriod.month:
        return DateFormat('MMMM yyyy', 'ar').format(state.selectedMonth);
      case DashboardPeriod.year:
        return state.selectedYear;
      case DashboardPeriod.custom:
        final range = state.customDateRange;
        if (range == null) return '';
        return '${DateFormat('dd/MM/yyyy').format(range.start)}'
            ' - ${DateFormat('dd/MM/yyyy').format(range.end)}';
    }
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: state.customDateRange,
    );
    if (picked != null && context.mounted) {
      context.read<DashboardCubit>().setCustomDateRange(picked);
    }
  }

  void _onPeriodChanged(BuildContext context, DashboardPeriod period) {
    if (period == DashboardPeriod.custom) {
      _pickCustomRange(context);
      return;
    }
    context.read<DashboardCubit>().setPeriod(period);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return sc.Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'الملخص المالي', subtitle: _rangeLabel),
          const SizedBox(height: 12),
          AppPeriodSelector<DashboardPeriod>(
            expanded: true,
            options: const [
              AppPeriodOption(value: DashboardPeriod.month, label: 'شهري'),
              AppPeriodOption(value: DashboardPeriod.year, label: 'سنوي'),
              AppPeriodOption(value: DashboardPeriod.custom, label: 'مخصص'),
            ],
            selected: state.period,
            onChanged: (period) => _onPeriodChanged(context, period),
          ),
          const SizedBox(height: 20),
          _CashBalance(amount: state.cashInHand),
          const SizedBox(height: 16),
          sc.Divider(color: scheme.border, height: 1),
          const SizedBox(height: 16),
          _SummaryStats(
            profit: state.totalProfit,
            customerDebt: state.totalCustomerDebt,
            supplierDebt: state.totalSupplierDebt,
            expenses: state.totalExpenses,
            withdrawals: state.totalWithdrawals,
          ),
        ],
      ),
    );
  }
}

class _CashBalance extends StatelessWidget {
  final double amount;

  const _CashBalance({required this.amount});

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الرصيد في الصندوق',
          style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                NumberFormatter.format(amount),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: scheme.chart2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                NumberFormatter.getCurrencySymbol(),
                style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryStats extends StatelessWidget {
  final double profit;
  final double customerDebt;
  final double supplierDebt;
  final double expenses;
  final double withdrawals;

  const _SummaryStats({
    required this.profit,
    required this.customerDebt,
    required this.supplierDebt,
    required this.expenses,
    required this.withdrawals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppStatTile(
                label: 'إجمالي الأرباح',
                value: NumberFormatter.formatShort(profit),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppStatTile(
                label: 'ديون العملاء',
                value: NumberFormatter.formatShort(customerDebt),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppStatTile(
                label: 'ديون الموردين',
                value: NumberFormatter.formatShort(supplierDebt),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppStatTile(
                label: 'إجمالي المصروفات',
                value: NumberFormatter.formatShort(expenses),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppStatTile(
          icon: sc.LucideIcons.banknote,
          label: 'إجمالي السحوبات',
          value: NumberFormatter.formatShort(withdrawals),
        ),
      ],
    );
  }
}
