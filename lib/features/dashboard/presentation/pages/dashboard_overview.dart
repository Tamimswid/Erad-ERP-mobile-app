import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/features/dashboard/presentation/widgets/app_bar_date_filter.dart';
import 'package:erad/features/dashboard/presentation/widgets/custom_app_drawe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../bloc/dashboard_cubit.dart';
import '../widgets/stats_grid.dart';
import '../widgets/financial_chart_section.dart';
import '../widgets/customer_count_card.dart';
import '../widgets/product_sales_section.dart';
import '../widgets/remaining_stock_section.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AppBarDateFilter(),
          ),
        ],
      ),

      body: BlocBuilder<DashboardCubit, DashboardState>(
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

          return Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: CustomScrollView(
              slivers: [
                // SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Stats Grid - 6 cards in a GridView
                SliverToBoxAdapter(child: const StatsGrid()),
                SliverToBoxAdapter(child: SizedBox(height: 24)),
                // Left: Financial Chart (larger)
                SliverToBoxAdapter(child: const FinancialChartSection()),
                SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: const CustomerCountCard()),
                SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: const ProductSalesSection()),
                SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: const RemainingStockSection()),
                SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: const RecentInvoicesSection()),
              ],
            ),
          );
        },
      ),
    );
  }
}

