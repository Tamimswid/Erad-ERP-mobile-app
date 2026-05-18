import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';

class ExpenseFormDialog extends StatefulWidget {
  final List<ExpenseCategory> categories;
  final Function(Expense expense) onSubmit;
  final Expense? expense;

  const ExpenseFormDialog({
    super.key,
    required this.categories,
    required this.onSubmit,
    this.expense,
  });

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _receiptController;
  late final TextEditingController _notesController;

  String? _selectedCategoryId;
  DateTime _expenseDate = DateTime.now();
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    _receiptController = TextEditingController(
      text: expense?.receiptNumber ?? '',
    );
    _notesController = TextEditingController(
      text: expense?.notes ?? '',
    );
    _selectedCategoryId = expense?.categoryId;
    _expenseDate = expense?.expenseDate ?? DateTime.now();
    _paymentMethod = expense?.paymentMethod ?? 'cash';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'تعديل المصروف' : 'إضافة مصروف جديد',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount
                      _buildLabel('المبلغ *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: _buildInputDecoration(
                          hint: 'أدخل المبلغ',
                          prefix: const Text('ل.س '),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'المبلغ مطلوب';
                          }
                          if (double.tryParse(value) == null) {
                            return 'المبلغ غير صالح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category
                      _buildLabel('الفئة'),
                      const SizedBox(height: 8),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),

                      // Description
                      _buildLabel('الوصف'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _buildInputDecoration(
                          hint: 'وصف المصروف',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date
                      _buildLabel('التاريخ *'),
                      const SizedBox(height: 8),
                      _buildDatePicker(),
                      const SizedBox(height: 8),
                      // Notes
                      _buildLabel('ملاحظات'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: _buildInputDecoration(
                          hint: 'ملاحظات إضافية (اختياري)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(isEditing ? 'حفظ التغييرات' : 'إضافة مصروف'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix != null ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: prefix,
      ) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategoryId,
          isExpanded: true,
          hint: const Text('اختر الفئة'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('بدون فئة'),
            ),
            ...widget.categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _expenseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() {
            _expenseDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              '${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final methods = [
      {'value': 'cash', 'label': 'نقدي', 'icon': Icons.money},
      {'value': 'card', 'label': 'بطاقة', 'icon': Icons.credit_card},
      {'value': 'transfer', 'label': 'تحويل', 'icon': Icons.account_balance},
    ];

    return Row(
      children: methods.map((method) {
        final isSelected = _paymentMethod == method['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _paymentMethod = method['value'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      method['icon'] as IconData,
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final category = widget.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => ExpenseCategory(
          id: '',
          userId: '',
          name: '',
          createdAt: DateTime.now(),
        ),
      );

      final expense = Expense(
        id: widget.expense?.id ?? '',
        userId: widget.expense?.userId ?? '',
        amount: amount,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryId != null ? category.name : null,
        expenseDate: _expenseDate,
        paymentMethod: _paymentMethod,
        receiptNumber: _receiptController.text.isEmpty
            ? null
            : _receiptController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSubmit(expense);
    }
  }
}
