import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:erad/core/constants/app_constants.dart';

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
        sc.Button(
          style: sc.ButtonStyle.ghost(),
          onPressed: () => Navigator.pop(context),
          child: const Text('لا'),
        ),
        sc.Button(
          style: sc.ButtonStyle.primary(),
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('نعم'),
        ),
      ],
    );
  }
}
