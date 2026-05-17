import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/suppliers_debts/data/models/invoice_model.dart';

export 'package:erad/features/suppliers_debts/data/models/invoice_model.dart';

class UnpaidInvoicesWidget extends StatelessWidget {
  final List<PurchaseInvoiceModel> invoices;
  final Function(String) onQuickPay;

  const UnpaidInvoicesWidget({
    super.key,
    required this.invoices,
    required this.onQuickPay,
  });

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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
          SizedBox(
            height: 420,
            child: unpaidInvoices.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد فواتير مستحقة',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppFonts.fontSizeMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: unpaidInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = unpaidInvoices[index];
                      return _buildInvoiceItem(context, invoice);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(BuildContext context, PurchaseInvoiceModel invoice) {
    final currencySymbol = NumberFormatter.getCurrencySymbol();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        invoice.invoiceNumber,
                        style: TextStyle(
                          fontSize: AppFonts.fontSizeSmall,
                          fontWeight: AppFonts.fontWeightMedium,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(invoice.paymentStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(invoice.paymentStatus),
                        style: TextStyle(
                          fontSize: AppFonts.fontSizeSmall - 2,
                          color: _getStatusColor(invoice.paymentStatus),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      invoice.invoiceDate.toString().substring(0, 10),
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol ${NumberFormatter.format(invoice.remainingAmount)}',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeMedium,
                  fontWeight: AppFonts.fontWeightBold,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'من $currencySymbol ${NumberFormatter.format(invoice.totalAmount)}',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeSmall - 2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'debt':
        return AppColors.warning;
      case 'partial':
        return AppColors.info;
      case 'paid':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'debt':
        return 'مستحق';
      case 'partial':
        return 'مدفوع جزئي';
      case 'paid':
        return 'مدفوع';
      default:
        return status;
    }
  }
}