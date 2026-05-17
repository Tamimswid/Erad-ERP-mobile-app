import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/sales_invoice.dart';
import '../../data/models/purchase_invoice.dart';
import '../../data/models/invoice_status.dart';
import '../../data/models/payment_status.dart';

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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.white.withValues(alpha: 0.95)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type and status
                Row(
                  children: [
                    // Type container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSale ? Icons.trending_up : Icons.trending_down,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSale ? 'sale' : 'purchase',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Status container - showing payment status
                    _buildStatusBadge(invoiceStatus, paymentStatus),
                  ],
                ),
                const SizedBox(height: 16),

                // Invoice number and party
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getInvoiceNumber(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPartyName(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Divider(
                  color: AppColors.secondary,
                  thickness: 0.3,
                  height: 0.5,
                ),
                const SizedBox(height: 16),

                // Date and amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تاريخ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                   
                         AppUtils.formatDate(_getInvoiceDate()),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'المجموع',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ AppUtils.formatNumber(_getTotalAmount())} ${NumberFormatter.getCurrencySymbol()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
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
    return InvoiceStatus.pending;
  }

  PaymentStatus _getPaymentStatus() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).paymentStatus;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).paymentStatus;
    }
    return PaymentStatus.cash;
  }

  Widget _buildStatusBadge(InvoiceStatus invoiceStatus, PaymentStatus paymentStatus) {
    // Use payment status to determine display - cash = paid, debt = pending
    final bool isPaid = paymentStatus == PaymentStatus.cash;
    final Color color = isPaid ? AppColors.success : AppColors.warning;
    final String label = isPaid ? 'مدفوعة' : 'مديون';
    final IconData icon = isPaid ? Icons.check_circle : Icons.access_time;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the old class for backward compatibility
class EnhancedInvoiceCard extends InvoiceCardWidget {
  const EnhancedInvoiceCard({
    super.key,
    required super.invoice,
    required super.type,
    required super.onTap,
  });
}
