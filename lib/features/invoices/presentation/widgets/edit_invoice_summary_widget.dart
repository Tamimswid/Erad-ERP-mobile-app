import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/utils/number_formatter.dart';
import '../bloc/edit_invoice_cubit.dart';

class EditInvoiceSummaryWidget extends StatefulWidget {
  const EditInvoiceSummaryWidget({super.key});

  @override
  State<EditInvoiceSummaryWidget> createState() =>
      _EditInvoiceSummaryWidgetState();
}

class _EditInvoiceSummaryWidgetState extends State<EditInvoiceSummaryWidget> {
  final _discountController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditInvoiceCubit, EditInvoiceState>(
      builder: (context, state) {
        if (state is! EditInvoiceLoaded) {
          return const SizedBox.shrink();
        }

        if (!_isInitialized) {
          _discountController.text = state.discountAmount.toString();
          _isInitialized = true;
        }

        final subtotal = state.subtotal;
        final discountAmount = state.discountAmount;
        final totalAmount = state.totalAmount;

        return sc.Card(
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(sc.LucideIcons.receiptText, 'ملخص الفاتورة'),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('المجموع الفرعي', subtotal),
                      const SizedBox(height: 8),
                      _buildDiscountRow(discountAmount),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'المجموع الكلي',
                        totalAmount,
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
              color: isTotal ? AppColors.moneyIn : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(double discountAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // const Text(
        //   'الخصم (المبلغ)',
        //   style: TextStyle(
        //     fontSize: AppFonts.fontSizeSmall,
        //     color: AppColors.textSecondary,
        //   ),
        // ),
        // const SizedBox(width: 8),
        SizedBox(
          width: 150,
          child: TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context.read<EditInvoiceCubit>().setDiscountAmount(amount);
            },
            onSubmitted: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context.read<EditInvoiceCubit>().setDiscountAmount(amount);
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
                horizontal: 10,
                vertical: 8,
              ),
              isDense: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          height: 40,
          child: sc.IconButton(
            variance: sc.ButtonStyle.outline(),
            icon: const Icon(sc.LucideIcons.plus, size: 18),
            onPressed: () {
              final amount = double.tryParse(_discountController.text) ?? 0.0;
              context.read<EditInvoiceCubit>().setDiscountAmount(amount);
              setState(() {});
            },
          ),
        ),
        const Spacer(),
        Text(
          '- ${AppUtils.formatNumber(discountAmount)} ${NumberFormatter.getCurrencySymbol()}',
          style: const TextStyle(
            fontWeight: AppFonts.fontWeightMedium,
            fontSize: AppFonts.fontSizeSmall,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}
