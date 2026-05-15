import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:flutter/material.dart';

class DebtCardWidget extends StatelessWidget {
  final CustomerDebtModel debt;
  final VoidCallback onTap;
  final VoidCallback onPaymentTap;
  final bool isEnd;
  final int index ;

  const DebtCardWidget({
    super.key,
    required this.debt,
    required this.onTap,
    required this.onPaymentTap,
    required this.isEnd, required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isFirs = index %2 == 0 ;
    return Container(
      // margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(

        color:isFirs ? AppColors.surface : AppColors.border.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(
            color: isEnd ? AppColors.border : Colors.transparent,
          ),
        ),
        borderRadius: isEnd
            ? BorderRadius.only(
                bottomRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              )
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Text(
                  debt.name,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Text(
                  NumberFormatter.formatCurrency(debt.totalInvoices),
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Text(
                  NumberFormatter.formatCurrency(debt.totalPaid),
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Text(
                  NumberFormatter.formatCurrency(debt.remainingDebt),
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightBold,
                    color: AppColors.primary,
                  ),
                ),
              ),
    
            ],
          ),
        ),
      ),
    );
  }
}
