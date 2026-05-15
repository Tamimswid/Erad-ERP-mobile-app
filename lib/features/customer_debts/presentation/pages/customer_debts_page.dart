import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/presentation/bloc/customer_debt_cubit.dart';
import 'package:erad/features/customer_debts/presentation/widgets/debt_stats_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/debt_card_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/debt_table_header_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/payment_dialog_widget.dart';
import 'package:erad/features/customer_debts/presentation/pages/customer_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerDebtsPage extends StatelessWidget {
  const CustomerDebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CustomerDebtCubit>()..getCustomerDebts(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<CustomerDebtCubit, CustomerDebtState>(
          listener: (context, state) {
            if (state is CustomerDebtError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            // Refresh data after successful payment to get customer names
            if (state is PaymentSuccess) {
              context.read<CustomerDebtCubit>().getCustomerDebts();
            }
          },
          builder: (context, state) {
            if (state is CustomerDebtLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CustomerDebtError) {
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
                          context.read<CustomerDebtCubit>().getCustomerDebts(),
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

            if (state is CustomerDebtLoaded) {
              final cubit = context.read<CustomerDebtCubit>();
              final debts = cubit.debtsWithDebt;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Stats Widget
                    DebtStatsWidget(
                      totalDebt: cubit.totalDebt,
                      totalInvoices: cubit.totalInvoices,
                      totalPaid: cubit.totalPaid,
                      debtorCount: cubit.debtorCount,
                    ),

                    const SizedBox(height: 24),


                    // Debt Cards List
                    if (debts.isEmpty)
                      _buildEmptyState()
                    else
                      const DebtTableHeaderWidget(),

                    Column(
                      children: debts.map((debt) {
                        return DebtCardWidget(
                          debt: debt,
                          onTap: () => _showCustomerDetails(context, debt),
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

  void _showCustomerDetails(BuildContext context, CustomerDebtModel debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailPage(customer: debt),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, CustomerDebtModel debt) {
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentDialogWidget(
        debt: debt,
        onPaymentSubmit: (amount, note, paymentDate) async {
          // Close dialog first
          Navigator.pop(dialogContext);

          // Add payment
          await context.read<CustomerDebtCubit>().addPayment(debt.id, amount, note, paymentDate);

          // Show success message on main page
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
