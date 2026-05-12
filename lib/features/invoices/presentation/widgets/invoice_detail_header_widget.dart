import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          // Back button
          SizedBox(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBackPressed,
                borderRadius: BorderRadius.circular(12),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          
          // Title and invoice number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'تفاصيل الفاتورة',
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeXXXLarge,
                        fontWeight: AppFonts.fontWeightBold,
                        color: AppColors.text,
                      ),
                    ),
                
                  ],
                ),
                const SizedBox(height: 4),
             Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'رقم الفاتورة: $invoiceNumber',
                        style: TextStyle(
                          fontSize: AppFonts.fontSizeSmall,
                          fontWeight: AppFonts.fontWeightMedium,
                          color: AppColors.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
