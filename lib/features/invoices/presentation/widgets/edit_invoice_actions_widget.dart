import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../bloc/edit_invoice_cubit.dart';

class EditInvoiceActionsWidget extends StatefulWidget {
  const EditInvoiceActionsWidget({super.key});

  @override
  State<EditInvoiceActionsWidget> createState() =>
      _EditInvoiceActionsWidgetState();
}

class _EditInvoiceActionsWidgetState extends State<EditInvoiceActionsWidget> {
  bool _isSaving = false;

  void _saveInvoice() async {
    final cubit = context.read<EditInvoiceCubit>();

    if (!cubit.canSave) {
      _showToast('يرجى إكمال جميع الحقول المطلوبة', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await cubit.saveInvoice();
      _showToast('تم تحديث الفاتورة بنجاح');
    } catch (e) {
      _showToast('فشل تحديث الفاتورة', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
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
                    style: sc.ButtonStyle.primary(),
                    onPressed: _isSaving ? null : _saveInvoice,
                    leading: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(sc.LucideIcons.save, size: 20),
                    child: Text(
                      _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: sc.Button(
                    style: sc.ButtonStyle.outline(),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    leading: const Icon(sc.LucideIcons.x, size: 20),
                    child: const Text('إلغاء'),
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
