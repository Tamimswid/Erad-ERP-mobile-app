import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class CustomerDetailHeaderWidget extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final VoidCallback onBackPressed;
  final VoidCallback? onPdfPressed;

  const CustomerDetailHeaderWidget({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.onBackPressed,
    this.onPdfPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.textSecondary,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeXLarge,
                    fontWeight: AppFonts.fontWeightBold,
                    color: AppColors.text,
                  ),
                ),
                if (customerPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        customerPhone,
                        style: TextStyle(
                          fontSize: AppFonts.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onPdfPressed != null)
            IconButton(
              icon: Icon(
                Icons.picture_as_pdf,
                color: AppColors.error,
                size: 24,
              ),
              onPressed: onPdfPressed,
            ),
        ],
      ),
    );
  }
}
