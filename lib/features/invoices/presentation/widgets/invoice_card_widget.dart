import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/sales_invoice.dart';
import '../../data/models/purchase_invoice.dart';

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
    final statusInfo = _getStatusInfo(invoice.paymentStatus.toString());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
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
                colors: [Colors.white, Colors.white.withOpacity(0.95)],
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
                    // Status container with real data
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo['backgroundColor'],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusInfo['borderColor'],
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusInfo['icon'],
                            size: 14,
                            color: statusInfo['color'],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusInfo['label'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusInfo['color'],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'SalesInvoiceStatus.paid':
      case 'PurchaseInvoiceStatus.paid':
        return {
          'label': 'مكتمل',
          'icon': Icons.check_circle,
          'color': AppColors.success,
          'backgroundColor': AppColors.success.withValues(alpha: 0.15),
          'borderColor': AppColors.success,
          'amountColor': AppColors.success,
        };
      case 'SalesInvoiceStatus.pending':
      case 'PurchaseInvoiceStatus.pending':
        return {
          'label': 'قيد الانتظار',
          'icon': Icons.access_time,
          'color': AppColors.secondary,
          'backgroundColor': AppColors.secondary.withValues(alpha: 0.15),
          'borderColor': AppColors.secondary,
          'amountColor': AppColors.secondary,
        };
      case 'SalesInvoiceStatus.overdue':
      case 'PurchaseInvoiceStatus.overdue':
        return {
          'label': 'تأخرت',
          'icon': Icons.error,
          'color': AppColors.warning,
          'backgroundColor': AppColors.warning.withValues(alpha: 0.15),
          'borderColor': AppColors.warning,
          'amountColor': AppColors.warning,
        };
      case 'SalesInvoiceStatus.cancelled':
      case 'PurchaseInvoiceStatus.cancelled':
        return {
          'label': 'تم الإلغاء',
          'icon': Icons.cancel,
          'color': AppColors.error,
          'backgroundColor': AppColors.error.withValues(alpha: 0.15),
          'borderColor': AppColors.error,
          'amountColor': AppColors.error,
        };
      default:
        return {
          'label': 'مجهول',
          'icon': Icons.help,
          'color': AppColors.error,
          'backgroundColor': AppColors.error.withValues(alpha: 0.15),
          'borderColor': AppColors.error,
          'amountColor': AppColors.error,
        };
    }
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = formatted.length - 1; i >= 0; i--) {
      counter++;
      if (counter % 3 == 0 && i != 0) {
        buffer.write(',');
      }
      buffer.write(formatted[formatted.length - 1 - i]);
    }
    return buffer.toString();
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
