import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';

class SupplierDetailHeaderWidget extends StatelessWidget {
  final String supplierName;
  final String supplierPhone;
  final VoidCallback onBackPressed;

  const SupplierDetailHeaderWidget({
    super.key,
    required this.supplierName,
    required this.supplierPhone,
    required this.onBackPressed,
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
                  supplierName,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeXLarge,
                    fontWeight: AppFonts.fontWeightBold,
                    color: AppColors.text,
                  ),
                ),
                if (supplierPhone.isNotEmpty) ...[
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
                        supplierPhone,
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
        ],
      ),
    );
  }
}