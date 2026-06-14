import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_cubit.dart';
import 'stat_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 0.5),
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(AppConstants.spacing),
          child: GridView(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppConstants.spacing,
              crossAxisSpacing: AppConstants.spacing,
              childAspectRatio: 1.3,
            ),
            children: [
              StatCard(
                title: 'صافي الربح',
                amount: state.netProfit,
                icon: Icons.savings_outlined,
                iconColor: const Color(0xFF14B8A6),
              ),
              StatCard(
                title: 'إجمالي الأرباح',
                amount: state.totalProfit,
                icon: Icons.trending_up_outlined,
                iconColor: const Color(0xFF6366F1),
              ),
              StatCard(
                title: 'إجمالي المصروفات',
                amount: state.totalExpenses,
                icon: Icons.attach_money_outlined,
                iconColor: const Color(0xFFEF4444),
              ),
              StatCard(
                title: 'إجمالي السحوبات',
                amount: state.totalWithdrawals,
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFFF59E0B),
              ),
              StatCard(
                title: 'ديون العملاء',
                amount: state.totalCustomerDebt,
                icon: Icons.people_outline,
                iconColor: const Color(0xFF3B82F6),
              ),
              StatCard(
                title: 'ديون الموردين',
                amount: state.totalSupplierDebt,
                icon: Icons.store_outlined,
                iconColor: const Color(0xFF10B981),
              ),
            ],
          ),
        );
      },
    );
  }
}
