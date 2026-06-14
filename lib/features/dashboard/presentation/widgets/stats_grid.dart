import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
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

        return Column(
          children: [
            TotalBigCard(
              color: AppColors.primary,
              count: NumberFormatter.formatShort(state.totalSalesRevenue),
              title: 'إجمالي المبيعات',
              fontColor: AppColors.surface,
            ),
            SizedBox(height: 3),
            TotalBigCard(
              color: AppColors.background,
              count: NumberFormatter.formatShort(state.totalPurchaseCost),
              title: 'إجمالي المشتريات',
              fontColor: AppColors.primary,
            ),
            SizedBox(height: 15),
            Row(
              children: [
                StatCard(
                  title: 'صافي الربح',
                  amount: state.netProfit,
                  icon: Icons.savings_outlined,
                  iconColor: const Color(0xFF14B8A6),
                ),
                StatCard(
                  title: 'السيولة النقدية',
                  amount: state.cashInHand,
                  icon: Icons.trending_up_outlined,
                  iconColor: const Color(0xFF6366F1),
                ),
              ],
            ),
            SizedBox(height: 15),

            Row(
              children: [
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
              ],
            ),
            SizedBox(height: 15),

            Row(
              children: [
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
          ],
        );
      },
    );
  }
}

class TotalBigCard extends StatelessWidget {
  const TotalBigCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.fontColor,
  });
  final String title;
  final String count;
  final Color color;
  final Color fontColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(width: 0.6, color: AppColors.border),
              borderRadius: BorderRadius.circular(3),
            ),
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w100,
                  ),
                ),
                Text(
                  count,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  NumberFormatter.getCurrencySymbol(),
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
