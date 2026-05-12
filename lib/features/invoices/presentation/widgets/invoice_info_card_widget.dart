import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/common_widgets.dart';
import 'package:erad/core/utils/number_formatter.dart';

class InvoiceInfoCardWidget extends StatelessWidget {
  final String invoiceDate;
  final String customerName;
  final String status;
  final String paymentStatus;
  final List<InvoiceItem> products;

  const InvoiceInfoCardWidget({
    super.key,
    required this.invoiceDate,
    required this.customerName,
    required this.status,
    required this.paymentStatus,
    required this.products,
  });

  Color getStatusColor(String status) {
    return InvoiceStatus.fromString(status).getColor;
  }

  Color getPaymentStatusColor(String paymentStatus) {
    return PaymentStatus.fromString(paymentStatus).getColor;
  }

  String getStatusText(String status) {
    return InvoiceStatus.fromString(status).getArabicName;
  }

  String getPaymentStatusText(String paymentStatus) {
    return PaymentStatus.fromString(paymentStatus).getArabicName;
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'draft':
      case 'sent':
        return Icons.access_time_outlined;
      case 'paid':
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'overdue':
        return Icons.warning_outlined;
      default:
        return Icons.access_time_outlined;
    }
  }

  IconData getPaymentStatusIcon(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'debt':
        return Icons.error_outline;
      case 'paid':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Info Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 2.5,
            children: [
              // Date Info
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: 'تاريخ الفاتورة',
                value: invoiceDate,
              ),

              // Customer Info
              _buildInfoItem(
                icon: Icons.person,
                label: 'اسم العميل',
                value: customerName,
              ),

              // Status Info
              _buildStatusInfoItem(
                icon: getStatusIcon(status),
                label: 'الحالة',
                status: status,
                isPaymentStatus: false,
              ),

              // Payment Status Info
              _buildStatusInfoItem(
                icon: getPaymentStatusIcon(paymentStatus),
                label: 'حالة الدفع',
                status: paymentStatus,
                isPaymentStatus: true,
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: AppColors.secondary.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 24),

          // Products Section
          _buildProductsSection(),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        // border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFonts.fontSizeLarge,
                  fontWeight: AppFonts.fontWeightMedium,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: AppFonts.fontSizeLarge,
              fontWeight: AppFonts.fontWeightSemiBold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoItem({
    required IconData icon,
    required String label,
    required String status,
    required bool isPaymentStatus,
  }) {
    final color = isPaymentStatus
        ? getPaymentStatusColor(status)
        : getStatusColor(status);
    final text = isPaymentStatus
        ? getPaymentStatusText(status)
        : getStatusText(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        // border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFonts.fontSizeLarge,
                  fontWeight: AppFonts.fontWeightMedium,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeSmall,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: color,
                    letterSpacing: 0.01,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'المنتجات',
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${products.length}',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table Header
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            // border: Border.all(color: AppColors.border),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              // border: Border(
              //   bottom: BorderSide(color: AppColors.primary, width: 2),
              // ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'اسم المنتج',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الكمية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'سعر الوحدة',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الإجمالي',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Products List
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(
              left: BorderSide(color: AppColors.border, width: 0.5),
              right: BorderSide(color: AppColors.border, width: 0.5),
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Column(
            children: products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _buildProductRow(product, index);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(InvoiceItem product, int index) {
    final name = product.productName;
    final quantity = product.quantity;
    final unitPrice = product.unitPrice;
    final total = product.totalPrice;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            style: index == products.length - 1
                ? BorderStyle.none
                : BorderStyle.solid,
            width: 0.5,
          ),
        ),
        color: index % 2 == 0 ? Colors.transparent : AppColors.background,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightMedium,
                color: AppColors.text,
              ),
            ),
          ),

          Expanded(
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${AppUtils.formatNumber(unitPrice)} ${NumberFormatter.getCurrencySymbol()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${AppUtils.formatNumber(total)} ${NumberFormatter.getCurrencySymbol()} ',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightBold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
