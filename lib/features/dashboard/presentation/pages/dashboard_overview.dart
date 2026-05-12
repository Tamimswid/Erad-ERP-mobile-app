import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../bloc/dashboard_cubit.dart';
import '../widgets/stats_grid.dart';
import '../widgets/financial_chart_section.dart';
import '../widgets/date_filter_section.dart';
import '../widgets/customer_count_card.dart';
import '../widgets/product_sales_section.dart';
import '../widgets/low_stock_section.dart';
import '../widgets/recent_invoices_section.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.sl<DashboardCubit>(),
      child: const _DashboardOverviewContent(),
    );
  }
}

class _DashboardOverviewContent extends StatelessWidget {
  const _DashboardOverviewContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return Container(
            color: AppColors.background,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'تحميل',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is DashboardError) {
          return Container(
            color: AppColors.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Grid - 6 cards in a row
                const StatsGrid(),
                const SizedBox(height: 24),
                // Middle Section: Chart + Date Filter + Customer Count
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Financial Chart (larger)
                    const Expanded(
                      flex: 3,
                      child: FinancialChartSection(),
                    ),
                    const SizedBox(width: 24),
                    // Right: Date Filter and Customer Count
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          const DateFilterSection(),
                          const SizedBox(height: 24),
                          const CustomerCountCard(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Bottom Section: Product Sales + Low Stock
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Sales Section
                    const Expanded(
                      child: ProductSalesSection(),
                    ),
                    const SizedBox(width: 24),
                    // Low Stock Section
                    const Expanded(
                      child: LowStockSection(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Recent Invoices Section
                const RecentInvoicesSection(),
              ],
            ),
          ),
        );
      },
    );
  }
}
