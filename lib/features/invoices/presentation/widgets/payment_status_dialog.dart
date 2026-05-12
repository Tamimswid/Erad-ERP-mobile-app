import 'package:flutter/material.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';

class PaymentStatusDialog extends StatefulWidget {
  final String currentStatus;
  final void Function(String) onStatusChanged;

  const PaymentStatusDialog({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  State<PaymentStatusDialog> createState() => _PaymentStatusDialogState();
}

class _PaymentStatusDialogState extends State<PaymentStatusDialog> {
  late String selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تحديث حالة الدفع'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('اختر الحالة الجديدة:'),
          const SizedBox(height: 16),
          ...PaymentStatus.values.map((status) {
            return RadioListTile<String>(
              title: Text(status.getArabicName),
              value: status.name,
              groupValue: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
              activeColor: status.getColor,
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onStatusChanged(selectedStatus);
            Navigator.pop(context);
          },
          child: const Text('تحديث'),
        ),
      ],
    );
  }
}
