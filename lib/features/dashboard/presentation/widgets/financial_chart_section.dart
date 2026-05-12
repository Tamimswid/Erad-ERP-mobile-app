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
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.04),
            //     blurRadius: 20,
            //     offset: const Offset(0, 4),
            //   ),
            // ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart with built-in filter buttons and title
              Padding(
                padding: const EdgeInsets.all(20),
                child: FinancialAreaChart(
                  categories: chartCategories,
                  showFilterButtons: true,
                  showLegend: true,
                  height: 320,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
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
        monthlyValues: [45000, 52000, 48000, 60000, 58000, 72000, 68000, 75000, 65000, 70000, 68000, 82000],
        lineColor: const Color(0xFF3B82F6),
      ),
      ChartCategory(
        id: 'purchases',
        name: 'المشتريات',
        monthlyValues: [28000, 32000, 30000, 35000, 34000, 42000, 40000, 44000, 36000, 41000, 38000, 48000],
        lineColor: const Color(0xFF10B981),
      ),
      ChartCategory(
        id: 'expenses',
        name: 'المصروفات',
        monthlyValues: [8000, 9500, 9000, 11000, 8500, 12000, 10000, 12500, 9000, 10500, 9500, 14000],
        lineColor: const Color(0xFFEF4444),
      ),
      ChartCategory(
        id: 'withdrawals',
        name: 'السحوبات',
        monthlyValues: [5000, 6000, 7000, 4000, 8000, 5500, 7000, 6500, 5000, 6000, 4500, 8000],
        lineColor: const Color(0xFFF59E0B),
      ),
      ChartCategory(
        id: 'profit',
        name: 'الأرباح',
        monthlyValues: [12000, 15000, 14000, 18000, 20000, 22000, 21000, 23000, 18000, 24000, 21000, 28000],
        lineColor: const Color(0xFF6366F1),
      ),
    ];
  }
}
