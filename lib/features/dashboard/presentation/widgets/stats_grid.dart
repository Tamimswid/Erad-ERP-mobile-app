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
            border: Border.all(color: AppColors.border,width: 0.5),
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(AppConstants.spacing),
          child: GridView(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppConstants.spacing,
              crossAxisSpacing: AppConstants.spacing,
              childAspectRatio: 1.4,
              // mainAxisExtent: 120,
            ),
            children:([
              // Total Sales Card
              StatCard(
                title: 'إجمالي مبيعات',
                amount: state.totalSales,
                icon: Icons.shopping_cart_outlined,
                iconColor: const Color(0xFF3B82F6),
              ),
              // const SizedBox(height: 16),
              // Total Purchases Card
              StatCard(
                title: 'إجمالي المشتريات',
                amount: state.totalPurchases,
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF10B981),
              ),
          
              // const SizedBox(width: 16),
              // Total Expenses Card
              StatCard(
                title: 'إجمالي المصروفات',
                amount: state.totalExpenses,
                icon: Icons.attach_money_outlined,
                iconColor: const Color(0xFFEF4444),
              ),
              // const SizedBox(width: 16),
              // Total Withdrawals Card
              StatCard(
                title: 'إجمالي السحوبات',
                amount: state.totalWithdrawals,
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFFF59E0B),
              ),
              // const SizedBox(width: 16),
              // Total Profit Card
              StatCard(
                title: 'إجمالي الأرباح',
                amount: state.totalProfit,
                icon: Icons.trending_up_outlined,
                iconColor: const Color(0xFF6366F1),
              ),
              // const SizedBox(width: 16),
              // Net Profit Card
              StatCard(
                title: 'صافي الربح',
                amount: state.netProfit,
                icon: Icons.savings_outlined,
                iconColor: const Color(0xFF14B8A6),
              ),
            ]),
          ),
        );
      },
    );
  }
}
