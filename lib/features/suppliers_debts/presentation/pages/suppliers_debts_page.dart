import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/presentation/bloc/supplier_debt_cubit.dart';
import 'package:erad/features/suppliers_debts/presentation/widgets/debt_stats_widget.dart';
import 'package:erad/features/suppliers_debts/presentation/widgets/debt_card_widget.dart';
import 'package:erad/features/suppliers_debts/presentation/widgets/payment_dialog_widget.dart';
import 'package:erad/features/suppliers_debts/presentation/pages/supplier_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SuppliersDebtsPage extends StatelessWidget {
  const SuppliersDebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SupplierDebtCubit>()..getSupplierDebts(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<SupplierDebtCubit, SupplierDebtState>(
          listener: (context, state) {
            if (state is SupplierDebtError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            if (state is SupplierPaymentSuccess) {
              context.read<SupplierDebtCubit>().getSupplierDebts();
            }
          },
          builder: (context, state) {
            if (state is SupplierDebtLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SupplierDebtError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'خطأ',
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeXXLarge,
                        fontWeight: AppFonts.fontWeightSemiBold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeMedium,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<SupplierDebtCubit>().getSupplierDebts(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'إعادة المحاولة',
                        style: TextStyle(color: AppColors.background),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is SupplierDebtLoaded) {
              final cubit = context.read<SupplierDebtCubit>();
              final debts = cubit.debtsWithDebt;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    DebtStatsWidget(
                      totalDebt: cubit.totalDebt,
                      totalInvoices: cubit.totalInvoices,
                      totalPaid: cubit.totalPaid,
                      debtorCount: cubit.debtorCount,
                    ),
                    const SizedBox(height: 24),
                    if (debts.isEmpty)
                      _buildEmptyState()
                    else
                 
                    Column(
                      children: debts.map((debt) {
                        return DebtCardWidget(
                          debt: debt,
                          onTap: () => _showSupplierDetails(context, debt),
                          onPaymentTap: () => _showPaymentDialog(context, debt),
                          isEnd: debts.indexOf(debt) == debts.length - 1,
                          index: debts.indexOf(debt),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2, size: 64, color: AppColors.secondary),
        const SizedBox(height: 16),
        Text(
          'لا توجد ديون مستحقة',
          style: TextStyle(
            fontSize: AppFonts.fontSizeXXLarge,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'تم سداد جميع الفواتير',
          style: TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showSupplierDetails(BuildContext context, SupplierDebtModel debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierDetailPage(supplier: debt),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, SupplierDebtModel debt) {
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentDialogWidget(
        debt: debt,
        onPaymentSubmit: (amount, note, paymentDate) async {
          Navigator.pop(dialogContext);
          await context.read<SupplierDebtCubit>().addPayment(debt.id, amount, note, paymentDate);
          if (context.mounted) {
            _showSuccessMessage(context, 'تم تسجيل الدفعة بنجاح');
          }
        },
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}