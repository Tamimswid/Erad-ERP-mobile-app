import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/common_widgets.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class InvoiceInfoGridWidget extends StatelessWidget {
  final String invoiceDate;
  final String customerName;
  final String status;
  final String paymentStatus;

  const InvoiceInfoGridWidget({
    super.key,
    required this.invoiceDate,
    required this.customerName,
    required this.status,
    required this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 2.5,
      children: [
        // Date Info
        _buildInfoItem(
          icon: sc.LucideIcons.calendar,
          label: 'Invoice Date',
          value: invoiceDate,
        ),

        // Customer Info
        _buildInfoItem(
          icon: sc.LucideIcons.user,
          label: 'Customer Name',
          value: customerName,
        ),

        // Status Info
        _buildStatusInfoItem(
          icon: getStatusIcon(status),
          label: 'Status',
          status: status,
          isPaymentStatus: false,
        ),

        // Payment Status Info
        _buildStatusInfoItem(
          icon: getPaymentStatusIcon(paymentStatus),
          label: 'Payment Status',
          status: paymentStatus,
          isPaymentStatus: true,
        ),
      ],
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
              fontSize: AppFonts.fontSizeMedium,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for status
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'draft':
      case 'sent':
        return sc.LucideIcons.clock;
      case 'paid':
      case 'completed':
        return sc.LucideIcons.circleCheck;
      case 'cancelled':
        return sc.LucideIcons.circleX;
      case 'overdue':
        return sc.LucideIcons.triangleAlert;
      default:
        return sc.LucideIcons.clock;
    }
  }

  Color getStatusColor(String status) {
    return InvoiceStatus.fromString(status).getColor;
  }

  String getStatusText(String status) {
    return InvoiceStatus.fromString(status).getArabicName;
  }

  IconData getPaymentStatusIcon(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'pending':
      case 'draft':
      case 'sent':
        return sc.LucideIcons.clock;
      case 'paid':
      case 'completed':
        return sc.LucideIcons.circleCheck;
      case 'cancelled':
        return sc.LucideIcons.circleX;
      case 'overdue':
        return sc.LucideIcons.triangleAlert;
      default:
        return sc.LucideIcons.clock;
    }
  }

  Color getPaymentStatusColor(String paymentStatus) {
    return PaymentStatus.fromString(paymentStatus).getColor;
  }

  String getPaymentStatusText(String paymentStatus) {
    return PaymentStatus.fromString(paymentStatus).getArabicName;
  }
}
