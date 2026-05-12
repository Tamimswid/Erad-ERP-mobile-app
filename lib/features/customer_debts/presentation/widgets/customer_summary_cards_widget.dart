import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:flutter/material.dart';

class CustomerSummaryCardsWidget extends StatelessWidget {
  final double totalInvoices;
  final double totalPaid;
  final double remainingDebt;

  const CustomerSummaryCardsWidget({
    super.key,
    required this.totalInvoices,
    required this.totalPaid,
    required this.remainingDebt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'إجمالي الفواتير',
            AppUtils.formatNumber(totalInvoices) ,
       
            Icons.receipt_long_outlined,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'إجمالي المبلغ المدفوع',
            AppUtils.formatNumber(totalPaid) ,
            Icons.payment_outlined,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'الديون المتبقية',
         AppUtils.formatNumber(remainingDebt), 
            Icons.account_balance_wallet_outlined,
            remainingDebt > 0 ? AppColors.error : AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    final currencySymbol = NumberFormatter.getCurrencySymbol();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppFonts.fontSizeSmall,
              fontWeight: AppFonts.fontWeightMedium,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                '$value $currencySymbol',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeXLarge,
                  fontWeight: AppFonts.fontWeightBold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
