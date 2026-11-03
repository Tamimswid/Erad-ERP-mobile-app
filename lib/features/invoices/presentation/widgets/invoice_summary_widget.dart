import 'package:erad/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../bloc/invoice_cubit.dart';

class InvoiceSummaryWidget extends StatefulWidget {
  const InvoiceSummaryWidget({super.key});

  @override
  State<InvoiceSummaryWidget> createState() => _InvoiceSummaryWidgetState();
}

class _InvoiceSummaryWidgetState extends State<InvoiceSummaryWidget> {
  final _discountController = TextEditingController(text: '0');
  final _discountAmountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _discountAmountController.dispose();
    super.dispose();
  }

  void _loadData() {
    final cubit = context.read<InvoiceCubit>();
    final discountAmount = cubit.discountAmount;
    _discountController.text = discountAmount.toString();
    _discountAmountController.text = AppUtils.formatNumber(discountAmount);
  }

  void _onDiscountAmountChanged(String value) {
    final discountAmount = double.tryParse(value) ?? 0.0;
    context.read<InvoiceCubit>().setDiscountAmount(discountAmount);
    _discountController.text = AppUtils.formatNumber(discountAmount);
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
        final remainingAmount = grandTotal - cubit.paidAmount;

        // Update discount controller when discount amount changes
        if (_discountController.text != discountAmount.toString() &&
            _discountController.text.isNotEmpty) {
          _discountController.text = AppUtils.formatNumber(discountAmount);
          _discountAmountController.text = AppUtils.formatNumber(discountAmount);
        }

        return sc.Card(
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(sc.LucideIcons.receiptText, 'ملخص الفاتورة'),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        sc.LucideIcons.package,
                        'عدد المنتجات',
                        '${cubit.invoiceItems.length} منتج',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow('المجموع الفرعي', subtotal),
                      const SizedBox(height: 6),
                      _buildDiscountRow(discountAmount, subtotal),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        'المجموع الكلي',
                        grandTotal,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: AppFonts.fontWeightMedium,
                fontSize: AppFonts.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: AppFonts.fontWeightSemiBold,
            fontSize: AppFonts.fontSizeSmall,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal
                  ? AppFonts.fontWeightSemiBold
                  : AppFonts.fontWeightMedium,
              fontSize: isTotal
                  ? AppFonts.fontSizeMedium
                  : AppFonts.fontSizeSmall,
              color: isTotal ? AppColors.text : AppColors.textSecondary,
            ),
          ),
          Text(
            '${AppUtils.formatNumber(amount)} ${NumberFormatter.getCurrencySymbol()}',
            style: TextStyle(
              fontWeight: isTotal
                  ? AppFonts.fontWeightSemiBold
                  : AppFonts.fontWeightMedium,
              fontSize: isTotal
                  ? AppFonts.fontSizeLarge
                  : AppFonts.fontSizeSmall,
              color: isTotal ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(double discountAmount, double subtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخصم (المبلغ)',
          style: const TextStyle(
            fontSize: AppFonts.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _discountAmountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  _onDiscountAmountChanged(value);
                  setState(() {});
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  isDense: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            sc.Button(
              style: sc.ButtonStyle.primary(),
              onPressed: () {
                final discountAmountValue = _discountAmountController.text;
                _onDiscountAmountChanged(discountAmountValue);
              },
              child: const Center(child: Text('طبق')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '- ${AppUtils.formatNumber(discountAmount)} ${NumberFormatter.getCurrencySymbol()}',
          style: const TextStyle(
            fontWeight: AppFonts.fontWeightMedium,
            fontSize: AppFonts.fontSizeSmall,
            color: AppColors.error,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

}
