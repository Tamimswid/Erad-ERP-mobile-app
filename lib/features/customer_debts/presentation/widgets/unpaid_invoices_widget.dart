import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/customer_debts/data/models/invoice_model.dart';
import 'package:erad/features/invoices/presentation/pages/invoice_detail_page.dart';
import 'package:flutter/material.dart';

export 'package:erad/features/customer_debts/data/models/invoice_model.dart';

/// واجهة فواتير الديون
class UnpaidInvoicesWidget extends StatelessWidget {
  final List<InvoiceModel> invoices;
  final Function(String invoiceId) onQuickPay;

  const UnpaidInvoicesWidget({
    super.key,
    required this.invoices,
    required this.onQuickPay,
  });

  /// عرض تفاصيل الفاتورة
  void _viewInvoiceDetails(BuildContext context, InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailPage(
          invoiceId: invoice.id,
          type: 'sale',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unpaidInvoices = invoices
        .where((invoice) => invoice.remainingAmount > 0)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'فواتير الديون',
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${unpaidInvoices.length}',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeSmall,
                      fontWeight: AppFonts.fontWeightMedium,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SizedBox(
            height: 420,
            child: unpaidInvoices.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'لا توجد فواتير ديون',
                            style: TextStyle(
                              fontSize: AppFonts.fontSizeMedium,
                              color: AppColors.success,
                              fontWeight: AppFonts.fontWeightMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: unpaidInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = unpaidInvoices[index];
                      return _buildInvoiceItem(context, invoice, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(
    BuildContext context,
    InvoiceModel invoice,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Invoice Number Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                invoice.invoiceNumber.substring(
                  invoice.invoiceNumber.length - 3,
                ),
                style: TextStyle(
                  color: AppColors.background,
                  fontSize: AppFonts.fontSizeSmall,
                  fontWeight: AppFonts.fontWeightBold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Invoice Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.invoiceDate,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // معلومات المبلغ وأزرار الإجراءات
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppUtils.formatNumber(invoice.remainingAmount)} ${NumberFormatter.getCurrencySymbol()}',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeMedium,
                  fontWeight: AppFonts.fontWeightBold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر عرض التفاصيل
                  TextButton.icon(
                    onPressed: () => _viewInvoiceDetails(context, invoice),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('عرض', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
