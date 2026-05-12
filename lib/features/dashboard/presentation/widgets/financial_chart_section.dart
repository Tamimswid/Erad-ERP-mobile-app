import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/financial_area_chart.dart';
import '../bloc/dashboard_cubit.dart';

class FinancialChartSection extends StatelessWidget {
  const FinancialChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) {
          return Container(
            height: 400,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final chartCategories = _buildChartCategories(state.monthlyChartData);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FinancialAreaChart(
              categories: chartCategories,
              showFilterButtons: true,
              showLegend: true,
              height: 320,
              padding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }

  List<ChartCategory> _buildChartCategories(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.isEmpty) {
      return _getDefaultCategories();
    }

    final salesValues = monthlyData.map((d) => (d['sales'] as num).toDouble()).toList();
    final purchasesValues = monthlyData.map((d) => (d['purchases'] as num).toDouble()).toList();
    final expensesValues = monthlyData.map((d) => (d['expenses'] as num).toDouble()).toList();
    final withdrawalsValues = monthlyData.map((d) => (d['withdrawals'] as num).toDouble()).toList();
    final profitValues = monthlyData.map((d) => (d['profit'] as num).toDouble()).toList();

    return [
      ChartCategory(
        id: 'sales',
        name: 'المبيعات',
        monthlyValues: salesValues,
        lineColor: const Color(0xFF3B82F6),
      ),
      ChartCategory(
        id: 'purchases',
        name: 'المشتريات',
        monthlyValues: purchasesValues,
        lineColor: const Color(0xFF10B981),
      ),
      ChartCategory(
        id: 'expenses',
        name: 'المصروفات',
        monthlyValues: expensesValues,
        lineColor: const Color(0xFFEF4444),
      ),
      ChartCategory(
        id: 'withdrawals',
        name: 'السحوبات',
        monthlyValues: withdrawalsValues,
        lineColor: const Color(0xFFF59E0B),
      ),
      ChartCategory(
        id: 'profit',
        name: 'الأرباح',
        monthlyValues: profitValues,
        lineColor: const Color(0xFF6366F1),
      ),
    ];
  }

  List<ChartCategory> _getDefaultCategories() {
    return [
      ChartCategory(
        id: 'sales',
        name: 'المبيعات',
        monthlyValues: [],
        lineColor: const Color(0xFF3B82F6),
      ),
      ChartCategory(
        id: 'purchases',
        name: 'المشتريات',
        monthlyValues: [],
        lineColor: const Color(0xFF10B981),
      ),
      ChartCategory(
        id: 'expenses',
        name: 'المصروفات',
        monthlyValues: [],
        lineColor: const Color(0xFFEF4444),
      ),
      ChartCategory(
        id: 'withdrawals',
        name: 'السحوبات',
        monthlyValues: [],
        lineColor: const Color(0xFFF59E0B),
      ),
      ChartCategory(
        id: 'profit',
        name: 'الأرباح',
        monthlyValues: [],
        lineColor: const Color(0xFF6366F1),
      ),
    ];
  }
}
