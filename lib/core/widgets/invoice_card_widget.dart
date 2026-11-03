import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class InvoiceCardWidget extends StatelessWidget {
  final dynamic invoice;
  final String type;
  final VoidCallback onTap;

  const InvoiceCardWidget({
    super.key,
    required this.invoice,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSale = type == 'sale';
    final invoiceStatus = _getInvoiceStatus();
    final paymentStatus = _getPaymentStatus();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: sc.Card(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: sc.Clickable(
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSale
                                ? sc.LucideIcons.trendingUp
                                : sc.LucideIcons.trendingDown,
                            size: 16,
                            color: AppColors.text,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSale ? 'sale' : 'purchase',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _buildStatusBadge(invoiceStatus, paymentStatus),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getInvoiceNumber(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPartyName(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: AppColors.divider,
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تاريخ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppUtils.formatDate(_getInvoiceDate()),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'المجموع',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppUtils.formatNumber(_getTotalAmount())} ${NumberFormatter.getCurrencySymbol()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInvoiceNumber() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).invoiceNumber;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).invoiceNumber;
    }
    return '';
  }

  String _getPartyName() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).customerName ?? '';
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).supplierName ?? '';
    }
    return '';
  }

  DateTime _getInvoiceDate() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).invoiceDate;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).invoiceDate;
    }
    return DateTime.now();
  }

  double _getTotalAmount() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).totalAmount;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).totalAmount;
    }
    return 0.0;
  }

  InvoiceStatus _getInvoiceStatus() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).status;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).status;
    }
    return InvoiceStatus.draft;
  }

  PaymentStatus _getPaymentStatus() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).paymentStatus;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).paymentStatus;
    }
    return PaymentStatus.cash;
  }

  Widget _buildStatusBadge(
    InvoiceStatus invoiceStatus,
    PaymentStatus paymentStatus,
  ) {
    final bool isPaid = paymentStatus == PaymentStatus.cash;
    final String label = isPaid ? 'مدفوعة' : 'مديون';
    final IconData icon = isPaid
        ? sc.LucideIcons.circleCheck
        : sc.LucideIcons.clock;
    final Color background = isPaid ? AppColors.primary : AppColors.muted;
    final Color foreground = isPaid
        ? AppColors.onPrimary
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPaid ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
