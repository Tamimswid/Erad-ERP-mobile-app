import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:flutter/material.dart';

class PaymentDialogWidget extends StatefulWidget {
  final SupplierDebtModel debt;
  final Function(double amount, String? note, String paymentDate) onPaymentSubmit;

  const PaymentDialogWidget({
    super.key,
    required this.debt,
    required this.onPaymentSubmit,
  });

  @override
  State<PaymentDialogWidget> createState() => _PaymentDialogWidgetState();
}

class _PaymentDialogWidgetState extends State<PaymentDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تسجيل دفعة',
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeXXLarge,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.text,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.debt.name,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'الدين المتبقي: ',
                        style: TextStyle(
                          fontSize: AppFonts.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        NumberFormatter.formatCurrency(widget.debt.remainingDebt),
                        style: TextStyle(
                          fontSize: AppFonts.fontSizeSmall,
                          fontWeight: AppFonts.fontWeightBold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'مبلغ الدفعة',
                      hintText: '0.00',
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
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: AppColors.primary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال المبلغ';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'الرجاء إدخال مبلغ صحيح';
                      }
                      if (amount > widget.debt.remainingDebt) {
                        return 'المبلغ لا يمكن أن يتجاوز الدين المتبقي';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                      hintText: 'إضافة ملاحظة...',
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
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(
                        Icons.note_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'تاريخ الدفعة',
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
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(
                          fontSize: AppFonts.fontSizeMedium,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final amount = double.parse(_amountController.text);
                        final note = _noteController.text.trim().isEmpty 
                            ? null 
                            : _noteController.text.trim();
                        final formattedDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                        
                        widget.onPaymentSubmit(amount, note, formattedDate);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                    child: Text(
                      'حفظ',
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeMedium,
                        color: AppColors.background,
                        fontWeight: AppFonts.fontWeightMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}