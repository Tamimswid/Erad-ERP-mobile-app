import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:flutter/material.dart';

class DebtStatsWidget extends StatelessWidget {
  final double totalDebt;
  final double totalInvoices;
  final double totalPaid;
  final int debtorCount;

  const DebtStatsWidget({
    super.key,
    required this.totalDebt,
    required this.totalInvoices,
    required this.totalPaid,
    required this.debtorCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Main Total Debt Section
          // Container(
          //   width: 56,
          //   height: 56,
          //   decoration: BoxDecoration(
          //     color: AppColors.primary.withOpacity(0.1),
          //     borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          //   ),
          //   child: Icon(
          //     Icons.account_balance_wallet,
          //     size: 28,
          //     color: AppColors.primary,
          //   ),
          // ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إجمالي الديون',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeSmall,
                  fontWeight: AppFonts.fontWeightMedium,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormatter.formatCurrency(totalDebt),
                style: TextStyle(
                  fontSize: AppFonts.fontSizeXXXLarge,
                  fontWeight: AppFonts.fontWeightBold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Sub Stats Grid
          Expanded(
            child: _buildStatItem(
              context,
              'مجموع الفواتير',
              NumberFormatter.formatCurrency(totalInvoices),
              Icons.receipt_long_outlined,
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: _buildStatItem(
              context,
              'المبلغ المدفوع',
              NumberFormatter.formatCurrency(totalPaid),
              Icons.payment_outlined,
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: _buildStatItem(
              context,
              'العملاء المدينون',
              debtorCount.toString(),
              Icons.people_outline,
              isNumber: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightRegular,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: AppFonts.fontSizeLarge,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
