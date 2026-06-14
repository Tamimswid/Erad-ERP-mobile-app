import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/features/dashboard/presentation/widgets/app_bar_date_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../bloc/dashboard_cubit.dart';
import '../widgets/stats_grid.dart';
import '../widgets/customer_count_card.dart';
import '../widgets/remaining_stock_section.dart';

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
        backgroundColor: AppColors.primary,
        title: const Text('لوحة التحكم',style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.surface,
        ),),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AppBarDateFilter(color: AppColors.surface,),
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
                SliverToBoxAdapter(child: const StatsGrid()),
                SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: const RemainingStockSection()),
              ],
            ),
          );
        },
      ),
    );
  }
}

