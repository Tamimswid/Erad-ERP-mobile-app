import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class PaymentModalWidget extends StatefulWidget {
  final double remainingDebt;
  final Function(double amount, String date, String? note) onPaymentSubmit;

  const PaymentModalWidget({
    super.key,
    required this.remainingDebt,
    required this.onPaymentSubmit,
  });

  @override
  State<PaymentModalWidget> createState() => _PaymentModalWidgetState();
}

class _PaymentModalWidgetState extends State<PaymentModalWidget> {
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

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
    bool mutedIcon = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
        icon,
        color: mutedIcon ? AppColors.textSecondary : AppColors.primary,
      ),
    );
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
        child: SingleChildScrollView(
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
                      sc.LucideIcons.x,
                      color: AppColors.textSecondary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'الديون المتبقية: ',
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      NumberFormatter.formatCurrency(widget.remainingDebt),
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeMedium,
                        fontWeight: AppFonts.fontWeightBold,
                        color: widget.remainingDebt > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
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
                      decoration: _decoration(
                        label: 'المبلغ *',
                        hint: '0.00',
                        icon: sc.LucideIcons.banknote,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال المبلغ';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'الرجاء إدخال مبلغ صالح';
                        }
                        if (amount > widget.remainingDebt) {
                          return 'لا يمكن أن يتجاوز المبلغ الدين المتبقي';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: _decoration(
                        label: 'ملاحظة (اختياري)',
                        hint: 'إضافة ملاحظة...',
                        icon: sc.LucideIcons.fileText,
                        mutedIcon: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: _decoration(
                          label: 'تاريخ الدفع',
                          hint: '',
                          icon: sc.LucideIcons.calendar,
                          mutedIcon: true,
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
                    child: sc.Button(
                      style: sc.ButtonStyle.outline(),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: sc.Button(
                      style: sc.ButtonStyle.primary(),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final amount = double.parse(_amountController.text);
                          final note = _noteController.text.trim().isEmpty
                              ? null
                              : _noteController.text.trim();
                          final formattedDate =
                              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                          widget.onPaymentSubmit(amount, formattedDate, note);
                        }
                      },
                      child: const Text('حفظ'),
                    ),
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
