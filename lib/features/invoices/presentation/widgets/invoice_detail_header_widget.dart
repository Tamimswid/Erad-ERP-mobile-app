import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class InvoiceDetailHeaderWidget extends StatelessWidget {
  final String invoiceNumber;
  final VoidCallback onBackPressed;

  const InvoiceDetailHeaderWidget({
    super.key,
    required this.invoiceNumber,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBackPressed,
            borderRadius: BorderRadius.circular(12),
            child: const Icon(
              sc.LucideIcons.arrowRight,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفاصيل الفاتورة',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeXXXLarge,
                  fontWeight: AppFonts.fontWeightBold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'رقم الفاتورة: $invoiceNumber',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeSmall,
                  fontWeight: AppFonts.fontWeightMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
