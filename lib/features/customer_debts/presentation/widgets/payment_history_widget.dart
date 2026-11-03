import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/customer_debts/data/models/payment_model.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

export 'package:erad/features/customer_debts/data/models/payment_model.dart';

/// صف دفعة واحدة في سجل المدفوعات
class PaymentHistoryRow extends StatelessWidget {
  final PaymentModel payment;
  final Function(String paymentId) onDeletePayment;

  const PaymentHistoryRow({
    super.key,
    required this.payment,
    required this.onDeletePayment,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'هل أنت متأكد من حذف هذه الدفعة بمبلغ ${NumberFormatter.formatCurrency(payment.amount)}؟',
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  sc.Button(
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  sc.Button(
                    style: sc.ButtonStyle.destructive(),
                    onPressed: () {
                      Navigator.pop(context);
                      onDeletePayment(payment.id);
                    },
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تفاصيل الدفعة',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDetailRow(
                'المبلغ',
                '${AppUtils.formatNumber(payment.amount)} ${NumberFormatter.getCurrencySymbol()}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow('التاريخ', payment.paymentDate),
              const SizedBox(height: 12),
              _buildDetailRow('طريقة الدفع', payment.paymentMethod),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow('الملاحظة', payment.notes!),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  sc.Button(
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;

    return sc.Card(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: sc.Clickable(
        onPressed: () => _showPaymentDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.muted,
                  borderRadius: theme.borderRadiusSm,
                ),
                child: Icon(
                  sc.LucideIcons.arrowDown,
                  size: 16,
                  color: scheme.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppUtils.formatNumber(payment.amount)} ${NumberFormatter.getCurrencySymbol()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${payment.paymentDate} · ${payment.paymentMethod}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showDeleteConfirmation(context),
                icon: Icon(
                  sc.LucideIcons.trash2,
                  color: scheme.destructive,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.destructive.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
