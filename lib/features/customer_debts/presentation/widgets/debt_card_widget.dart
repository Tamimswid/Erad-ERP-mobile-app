import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:flutter/material.dart';

class DebtCardWidget extends StatelessWidget {
  final CustomerDebtModel debt;
  final VoidCallback onTap;
  final VoidCallback onPaymentTap;
  final bool isEnd;
  final int index;
  final bool showPaymentButton;

  const DebtCardWidget({
    super.key,
    required this.debt,
    required this.onTap,
    required this.onPaymentTap,
    this.isEnd = false,
    this.index = 0,
    this.showPaymentButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = debt.remainingDebt;
    final hasDebt = remaining > 0;

    return 
  Card(
        margin: EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.name,
                            style: TextStyle(
                              fontSize: AppFonts.fontSizeLarge,
                              fontWeight: AppFonts.fontWeightSemiBold,
                              color: AppColors.text,
                            ),
                          ),
                          if (debt.phone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              debt.phone!,
                              style: TextStyle(
                                fontSize: AppFonts.fontSizeSmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hasDebt
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasDebt
                            ? '${NumberFormatter.format(remaining)} ${NumberFormatter.getCurrencySymbol()}'
                            : 'مدفوع',
                        style: TextStyle(
                          fontSize: AppFonts.fontSizeSmall,
                          fontWeight: AppFonts.fontWeightSemiBold,
                          color: hasDebt
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'إجمالي الفواتير',
                      '${NumberFormatter.format(debt.totalInvoices)} ${NumberFormatter.getCurrencySymbol()}',
                    ),
                    _buildStatItem(
                      'المدفوع',
                      '${NumberFormatter.format(debt.totalPaid)} ${NumberFormatter.getCurrencySymbol()}',
                    ),
                    _buildStatItem(
                      'الديون',
                      '${NumberFormatter.format(remaining)} ${NumberFormatter.getCurrencySymbol()}',
                    ),
                  ],
                ),
                if (hasDebt && showPaymentButton) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: onPaymentTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'تسجيل دفعة',
                        style: TextStyle(color: AppColors.background),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );    
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFonts.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
