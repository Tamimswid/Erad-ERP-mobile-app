import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';

class DebtTableHeaderWidget extends StatelessWidget {
  const DebtTableHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'المورد',
              style: TextStyle(
                fontSize: AppFonts.fontSizeSmall,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'الرصيد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFonts.fontSizeSmall,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 100),
        ],
      ),
    );
  }
}