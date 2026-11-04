import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../bloc/expense_cubit.dart';
import 'expense_form_dialog.dart';

class ExpenseListWidget extends StatelessWidget {
  final List<Expense> expenses;
  final List<ExpenseCategory> categories;

  const ExpenseListWidget({
    super.key,
    required this.expenses,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return _buildEmptyState();
    }
    return _buildExpenseList(context);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            sc.LucideIcons.receiptText,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مصروفات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف مصروف جديد للبدء',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ExpenseCard(expense: expense, categories: categories);
      },
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final List<ExpenseCategory> categories;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return sc.Card(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExpenseDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    sc.LucideIcons.receiptText,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description ?? 'مصروف',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (expense.categoryName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.muted,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                expense.categoryName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            sc.LucideIcons.calendar,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormatter.format(expense.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormatter.getCurrencySymbol(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Text('تفاصيل المصروف'),
            const Spacer(),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showEditDialog(context);
                  },
                  icon: Icon(sc.LucideIcons.pencil, color: AppColors.primary),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showDeleteConfirmation(context);
                  },
                  icon: Icon(sc.LucideIcons.trash2, color: AppColors.error),
                ),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('المبلغ', NumberFormatter.format(expense.amount)),
              _buildDetailRow(
                'طريقة الدفع',
                _getPaymentMethodText(expense.paymentMethod),
              ),
              _buildDetailRow(
                'التاريخ',
                '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
              ),
              if (expense.categoryName != null)
                _buildDetailRow('الفئة', expense.categoryName!),
              if (expense.receiptNumber != null)
                _buildDetailRow('رقم الإيصال', expense.receiptNumber!),
              if (expense.notes != null)
                _buildDetailRow('ملاحظات', expense.notes!),
            ],
          ),
        ),
        actions: [
          sc.Button(
            alignment: Alignment.center,
            style: sc.ButtonStyle.ghost(),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'card':
        return 'بطاقة';
      case 'transfer':
        return 'تحويل';
      default:
        return method;
    }
  }

  void _showEditDialog(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => ExpenseFormDialog(
        expense: expense,
        categories: categories,
        onSubmit: (updatedExpense) {
          cubit.updateExpense(updatedExpense);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('هل أنت متأكد من حذف هذا المصروف؟'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.destructive(),
                    onPressed: () {
                      cubit.deleteExpense(expense.id);
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
