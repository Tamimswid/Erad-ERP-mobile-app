import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../bloc/edit_invoice_cubit.dart';

class EditInvoiceActionsWidget extends StatefulWidget {
  const EditInvoiceActionsWidget({super.key});

  @override
  State<EditInvoiceActionsWidget> createState() =>
      _EditInvoiceActionsWidgetState();
}

class _EditInvoiceActionsWidgetState extends State<EditInvoiceActionsWidget> {
  bool _isSaving = false;

  Future<void> _saveInvoice() async {
    setState(() => _isSaving = true);
    // The page listener surfaces success/error and pops on success.
    await context.read<EditInvoiceCubit>().saveInvoice();
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return sc.Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.primary(),
                    onPressed: _isSaving ? null : _saveInvoice,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(sc.LucideIcons.save, size: 20),
                        const SizedBox(width: 8),
                        Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.outline(),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sc.LucideIcons.x, size: 20),
                        SizedBox(width: 8),
                        Text('إلغاء'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
