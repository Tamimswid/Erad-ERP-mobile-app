import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

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
        sc.Button(
          alignment: Alignment.center,
          style: sc.ButtonStyle.ghost(),
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        sc.Button(
          alignment: Alignment.center,
          style: sc.ButtonStyle.destructive(),
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('حذف'),
        ),
      ],
    );
  }
}
