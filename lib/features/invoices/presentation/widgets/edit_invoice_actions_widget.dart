import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveInvoice,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.save, size: 20),
                    label: Text(
                      _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                      style: const TextStyle(
                        fontWeight: AppFonts.fontWeightSemiBold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(0),
                      backgroundColor: _isSaving
                          ? AppColors.primary.withValues(alpha: 0.7)
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontWeight: AppFonts.fontWeightSemiBold,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(0),
                      foregroundColor: AppColors.text,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
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
