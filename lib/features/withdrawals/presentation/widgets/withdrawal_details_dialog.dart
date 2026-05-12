import 'package:flutter/material.dart';
import '../../data/models/withdrawal.dart';

class WithdrawalDetailsDialog extends StatelessWidget {
  final Withdrawal withdrawal;

  const WithdrawalDetailsDialog({
    super.key,
    required this.withdrawal,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تفاصيل السحب'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (withdrawal.description != null)
              Text('الوصف: ${withdrawal.description!}'),
            Text('المبلغ: ${withdrawal.amount.toStringAsFixed(2)} ل.س'),
            Text('طريقة الدفع: ${withdrawal.paymentMethod}'),
            Text('التاريخ: ${withdrawal.withdrawalDate.toString().split(' ')[0]}'),
            if (withdrawal.notes != null) Text('ملاحظات: ${withdrawal.notes!}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  static void show(BuildContext context, Withdrawal withdrawal) {
    showDialog(
      context: context,
      builder: (context) => WithdrawalDetailsDialog(withdrawal: withdrawal),
    );
  }
}
