import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../bloc/invoice_cubit.dart';

class InvoiceActionsWidget extends StatefulWidget {
  const InvoiceActionsWidget({super.key});

  @override
  State<InvoiceActionsWidget> createState() => _InvoiceActionsWidgetState();
}

class _InvoiceActionsWidgetState extends State<InvoiceActionsWidget> {
  String _currentPaymentType = 'debt';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialStatus();
    });
  }

  void _loadInitialStatus() {
    final cubit = context.read<InvoiceCubit>();
    setState(() {
      _currentPaymentType = cubit.paymentType;
    });
  }

  void _onPaymentTypeChanged(String? value) {
    if (value != null) {
      context.read<InvoiceCubit>().setPaymentType(value);
      setState(() {
        _currentPaymentType = value;
      });
    }
  }

  void _saveInvoice() async {
    final cubit = context.read<InvoiceCubit>();

    if (!cubit.canSaveInvoice) {
      _showToast('يرجى إكمال جميع الحقول المطلوبة', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await cubit.saveInvoice();
      _showToast('تم حفظ الفاتورة بنجاح');
    } catch (e) {
      _showToast('فشل حفظ الفاتورة: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _deleteInvoice() async {
    final confirmed = await _showConfirmationDialog(
      'تأكيد الحذف',
      'هل أنت متأكد من حذف هذه الفاتورة؟',
    );
    
    if (confirmed == true) {
      _showToast('تم حذف الفاتورة');
    }
  }

  // void _exportToPDF() {
  //   final cubit = context.read<InvoiceCubit>();
    
  //   if (!cubit.canSaveInvoice) {
  //     _showToast('يرجى إكمال جميع الحقول المطلوبة أولاً', isError: true);
  //     return;
  //   }

  //   _showToast('جاري إنشاء ملف PDF...');

  //   Future.delayed(const Duration(seconds: 2), () {
  //     _showToast('تم إنشاء ملف PDF بنجاح');
  //   });
  // }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                sc.Button(
                  style: sc.ButtonStyle.ghost(),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                sc.Button(
                  style: sc.ButtonStyle.primary(),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('تأكيد'),
                ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Status Dropdown
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonFormField<String>(
              value: _currentPaymentType,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixIcon: Icon(
                  sc.LucideIcons.banknote,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: _isSaving ? AppColors.textSecondary : AppColors.text,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'cash',
                  child: Text('مدفوعة نقدا'),
                ),
                DropdownMenuItem(
                  value: 'debt',
                  child: Text('مديون'),
                ),
              ],
              onChanged: _isSaving ? null : _onPaymentTypeChanged,
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: sc.Button(
                    style: sc.ButtonStyle.primary(),
                    onPressed: _isSaving ? null : _saveInvoice,
                    leading: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: sc.CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(sc.LucideIcons.save, size: 18),
                    child: Text(_isSaving ? 'جاري...' : 'حفظ'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: sc.Button(
                    style: sc.ButtonStyle.destructive(),
                    onPressed: _isSaving ? null : _deleteInvoice,
                    leading: const Icon(sc.LucideIcons.trash2, size: 18),
                    child: const Text('حذف'),
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