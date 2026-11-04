import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/app_period_selector.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class InvoiceActionsWidget extends StatefulWidget {
  const InvoiceActionsWidget({super.key});

  @override
  State<InvoiceActionsWidget> createState() => _InvoiceActionsWidgetState();
}

class _InvoiceActionsWidgetState extends State<InvoiceActionsWidget> {
  bool _isSaving = false;

  Future<void> _saveInvoice() async {
    final cubit = context.read<InvoiceCubit>();

    if (cubit.paymentType == null) {
      _showToast('اختر نوع الدفع أولاً', isError: true);
      return;
    }

    if (!cubit.canSaveInvoice) {
      _showToast('يرجى إكمال بيانات الفاتورة والمنتجات', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final saved = await cubit.saveInvoice();

    if (!mounted) return;

    if (saved) {
      _showToast('تم حفظ الفاتورة بنجاح');
    } else {
      final state = cubit.state;
      _showToast(
        state is InvoiceError ? state.message : 'فشل حفظ الفاتورة',
        isError: true,
      );
    }

    setState(() => _isSaving = false);
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : null,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        final cubit = context.read<InvoiceCubit>();

        return sc.Card(
          padding: const EdgeInsets.all(AppConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    sc.LucideIcons.banknote,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'نوع الدفع',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  if (cubit.paymentType == null)
                    const Text(
                      'اختر أحد الخيارين',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              AppPeriodSelector<String>(
                expanded: true,
                options: const [
                  AppPeriodOption(value: 'debt', label: 'آجل'),
                  AppPeriodOption(value: 'cash', label: 'نقدي'),
                ],
                selected: cubit.paymentType,
                onChanged: (type) {
                  if (!_isSaving) cubit.setPaymentType(type);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: sc.Button(
                  alignment: Alignment.center,
                  style: sc.ButtonStyle.primary(),
                  onPressed: _isSaving ? null : _saveInvoice,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: sc.CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(sc.LucideIcons.save, size: 18),
                      const SizedBox(width: 8),
                      Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الفاتورة'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
