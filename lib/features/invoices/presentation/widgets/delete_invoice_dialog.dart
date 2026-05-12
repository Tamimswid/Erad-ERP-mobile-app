import 'package:flutter/material.dart';

class DeleteInvoiceDialog extends StatelessWidget {
  final String invoiceNumber;
  final VoidCallback onConfirm;

  const DeleteInvoiceDialog({
    super.key,
    required this.invoiceNumber,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('حذف الفاتورة'),
      content: Text(
        'هل أنت متأكد من حذف فاتورة #$invoiceNumber؟ لا يمكن التراجع عن هذا الإجراء.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('حذف', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
