import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';

class PartyInvoiceEmptyState extends StatelessWidget {
  const PartyInvoiceEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(sc.LucideIcons.receiptText,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'لا توجد فواتير',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
