import 'package:flutter/material.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';

class InvoiceStatusDialog extends StatefulWidget {
  final String currentStatus;
  final void Function(String value) onUpdate;

  const InvoiceStatusDialog({
    super.key,
    required this.currentStatus,
    required this.onUpdate,
  });

  @override
  State<InvoiceStatusDialog> createState() => _InvoiceStatusDialogState();
}

class _InvoiceStatusDialogState extends State<InvoiceStatusDialog> {
  late String selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تحديث حالة الفاتورة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('اختر الحالة الجديدة:'),
          const SizedBox(height: 16),
          ...InvoiceStatus.values.map((status) {
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
            widget.onUpdate(selectedStatus);
            Navigator.pop(context);
          },
          child: const Text('تحديث'),
        ),
      ],
    );
  }
}
