import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/invoice_cubit.dart';

class InvoiceActionsWidget extends StatefulWidget {
  const InvoiceActionsWidget({super.key});

  @override
  State<InvoiceActionsWidget> createState() => _InvoiceActionsWidgetState();
}

class _InvoiceActionsWidgetState extends State<InvoiceActionsWidget> {
  String _currentStatus = 'draft';
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
      _currentStatus = cubit.status;
      _currentPaymentType = cubit.paymentType;
    });
  }

  void _onStatusChanged(String? value) {
    if (value != null) {
      context.read<InvoiceCubit>().setStatus(value);
      setState(() {
        _currentStatus = value;
      });
    }
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

  void _exportToPDF() {
    final cubit = context.read<InvoiceCubit>();
    
    if (!cubit.canSaveInvoice) {
      _showToast('يرجى إكمال جميع الحقول المطلوبة أولاً', isError: true);
      return;
    }

    _showToast('جاري إنشاء ملف PDF...');

    Future.delayed(const Duration(seconds: 2), () {
      _showToast('تم إنشاء ملف PDF بنجاح');
    });
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
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
    final cubit = context.read<InvoiceCubit>();
    final currentStatus = cubit.status;
    
    if (currentStatus != _currentStatus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentStatus = currentStatus;
        });
      });
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1),
      ),
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
              value: _currentStatus,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixIcon: Icon(
                  Icons.info_outline,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
              style: TextStyle(
                fontSize: 13,
                color: _isSaving ? AppColors.textSecondary : AppColors.text,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'draft',
                  child: Text('مسودة'),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('مكتملة'),
                ),
                DropdownMenuItem(
                  value: 'approved',
                  child: Text('معتمدة'),
                ),
                DropdownMenuItem(
                  value: 'cancelled',
                  child: Text('ملغاة'),
                ),
              ],
              onChanged: _isSaving ? null : _onStatusChanged,
            ),
          ),
          const SizedBox(height: 12),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveInvoice,
                    icon: _isSaving 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                    label: Text(
                      _isSaving ? 'جاري...' : 'حفظ',
                      style: const TextStyle(
                        fontWeight: AppFonts.fontWeightSemiBold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaving ? AppColors.primary.withOpacity(0.7) : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _deleteInvoice,
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(
                      'حذف',
                      style: const TextStyle(
                        fontWeight: AppFonts.fontWeightSemiBold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaving ? AppColors.error.withOpacity(0.5) : AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _exportToPDF,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(
                      'PDF',
                      style: const TextStyle(
                        fontWeight: AppFonts.fontWeightSemiBold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaving ? AppColors.secondary.withOpacity(0.5) : AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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