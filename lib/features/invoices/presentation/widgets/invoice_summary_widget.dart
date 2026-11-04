import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class InvoiceSummaryWidget extends StatefulWidget {
  const InvoiceSummaryWidget({super.key});

  @override
  State<InvoiceSummaryWidget> createState() => _InvoiceSummaryWidgetState();
}

class _InvoiceSummaryWidgetState extends State<InvoiceSummaryWidget> {
  final _discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _loadData() {
    if (!mounted) return;
    final discountAmount = context.read<InvoiceCubit>().discountAmount;
    _discountController.text = AppUtils.formatNumber(discountAmount);
  }

  void _applyDiscount() {
    final cubit = context.read<InvoiceCubit>();
    final subtotal = cubit.calculateSubtotal();
    final value = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final discountAmount = value.clamp(0.0, subtotal);
    cubit.setDiscountAmount(discountAmount);
    _discountController.text = AppUtils.formatNumber(discountAmount);
    _discountController.selection = TextSelection.collapsed(
      offset: _discountController.text.length,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        final cubit = context.read<InvoiceCubit>();
        final subtotal = cubit.calculateSubtotal();
        final discountAmount = cubit.discountAmount;
        final grandTotal = subtotal - discountAmount;

        return sc.Card(
          padding: const EdgeInsets.all(AppConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'ملخص الفاتورة',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${cubit.invoiceItems.length} منتج',
                    style: const TextStyle(
                      fontSize: AppFonts.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInfoRow('المجموع الفرعي', subtotal),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _applyDiscount(),
                      decoration: InputDecoration(
                        hintText: 'مبلغ الخصم',
                        prefixIcon: const Icon(
                          sc.LucideIcons.percent,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 42,
                    child: sc.Button(
                      alignment: Alignment.center,
                      style: sc.ButtonStyle.secondary(),
                      onPressed: _applyDiscount,
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
              if (discountAmount > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'الخصم المطبق: - ${AppUtils.formatNumber(discountAmount)} ${NumberFormatter.getCurrencySymbol()}',
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'الإجمالي',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${AppUtils.formatNumber(grandTotal)} ${NumberFormatter.getCurrencySymbol()}',
                    style: const TextStyle(
                      fontSize: AppFonts.fontSizeLarge,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.moneyIn,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFonts.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${AppUtils.formatNumber(amount)} ${NumberFormatter.getCurrencySymbol()}',
          style: const TextStyle(
            fontSize: AppFonts.fontSizeSmall,
            fontWeight: AppFonts.fontWeightMedium,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
