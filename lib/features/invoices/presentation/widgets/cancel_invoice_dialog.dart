import 'package:flutter/material.dart';

class CancelInvoiceDialog extends StatelessWidget {
  final String invoiceNumber;
  final VoidCallback onConfirm;

  const CancelInvoiceDialog({
    super.key,
    required this.invoiceNumber,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إلغاء الفاتورة'),
      content: Text('هل أنت متأكد من إلغاء فاتورة #$invoiceNumber؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لا'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('نعم', style: TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }
}
