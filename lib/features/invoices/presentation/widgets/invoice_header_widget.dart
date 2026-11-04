import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';

class InvoiceHeaderWidget extends StatelessWidget {
  final int invoiceCount;
  final VoidCallback onNewInvoice;

  const InvoiceHeaderWidget({
    super.key,
    required this.invoiceCount,
    required this.onNewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              sc.LucideIcons.fileText,
              color: AppColors.text,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Title and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'invoices',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$invoiceCount ${NumberFormatter.getCurrencySymbol()}invoice_count',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Button
          sc.Button(
            alignment: Alignment.center,
            style: sc.ButtonStyle.primary(),
            onPressed: onNewInvoice,
            leading: const Icon(sc.LucideIcons.plus, size: 18),
            child: const Text('new_invoice'),
          ),
        ],
      ),
    );
  }
}
