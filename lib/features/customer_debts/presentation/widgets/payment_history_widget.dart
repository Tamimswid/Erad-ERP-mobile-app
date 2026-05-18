import 'dart:developer';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/customer_debts/data/models/payment_model.dart';
import 'package:flutter/material.dart';

export 'package:erad/features/customer_debts/data/models/payment_model.dart';

/// واجهة سجل المدفوعات
class PaymentHistoryWidget extends StatelessWidget {
  final List<PaymentModel> payments;
  final VoidCallback onAddPayment;
  final Function(String paymentId) onDeletePayment;

  const PaymentHistoryWidget({
    super.key,
    required this.payments,
    required this.onAddPayment,
    required this.onDeletePayment,
  });

  /// عرض dialog تأكيد الحذف
  void _showDeleteConfirmation(BuildContext context, PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه الدفعة بمبلغ ${NumberFormatter.formatCurrency(payment.amount)}؟',
          textAlign: TextAlign.right,
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDeletePayment(payment.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Icons.history_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'سجل المدفوعات',
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onAddPayment,
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(
                    'إضافة',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SizedBox(
            height: 420,
            child: payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 32,
                          color: AppColors.textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد مدفوعات',
                          style: TextStyle(
                            fontSize: AppFonts.fontSizeMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return _buildPaymentItem(context, payment, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
    BuildContext context,
    PaymentModel payment,
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
          // Payment Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_downward_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Payment Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                 '${AppUtils.formatNumber(payment.amount)} ${NumberFormatter.getCurrencySymbol()}',
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightBold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${payment.paymentDate} · ${payment.paymentMethod}',
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // زر الحذف مع تأكيد
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, payment),
            icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.1),
              padding: const EdgeInsets.all(6),
            ),
          ),
        ],
      ),
    );
  }
}
