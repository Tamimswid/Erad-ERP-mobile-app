import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/invoice_cubit.dart';

class InvoiceTypeSelectorWidget extends StatefulWidget {
  const InvoiceTypeSelectorWidget({super.key});

  @override
  State<InvoiceTypeSelectorWidget> createState() => _InvoiceTypeSelectorWidgetState();
}

class _InvoiceTypeSelectorWidgetState extends State<InvoiceTypeSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        final cubit = context.read<InvoiceCubit>();
        
        return SizedBox(
          height: 240,
          child: Card(
            elevation: AppConstants.cardElevation,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
              side: BorderSide(color: AppColors.border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSectionTitle(Icons.receipt_long, 'معلومات الفاتورة'),
                  // const SizedBox(height: 16),
                const  Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeOption(
                          context,
                          'sale',
                          'فاتورة مبيعات',
                          cubit.invoiceType == 'sale',
                          cubit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeOption(
                          context,
                          'purchase',
                          'فاتورة مشتريات',
                          cubit.invoiceType == 'purchase',
                          cubit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDebtTypeOption(
                          context,
                          'debtor',
                          'آجل',
                          cubit.debtType == 'debtor',
                          cubit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDebtTypeOption(
                          context,
                          'creditor',
                          'نقدي',
                          cubit.debtType == 'creditor',
                          cubit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  Widget _buildTypeOption(
    BuildContext context,
    String type,
    String title,
    bool isSelected,
    InvoiceCubit cubit,
  ) {
    return GestureDetector(
      onTap: () {
        cubit.setInvoiceType(type);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'sale' ? Icons.trending_up : Icons.trending_down,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? AppFonts.fontWeightSemiBold : AppFonts.fontWeightMedium,
                color: isSelected ? AppColors.primary : AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtTypeOption(
    BuildContext context,
    String type,
    String title,
    bool isSelected,
    InvoiceCubit cubit,
  ) {
    return GestureDetector(
      onTap: () {
        cubit.setDebtType(type);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'debtor' ? Icons.arrow_downward : Icons.arrow_upward,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? AppFonts.fontWeightSemiBold : AppFonts.fontWeightMedium,
                color: isSelected ? AppColors.primary : AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}