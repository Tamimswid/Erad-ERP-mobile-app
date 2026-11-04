import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:erad/core/constants/app_constants.dart';

class DiscountWidget extends StatefulWidget {
  final double subtotal;
  final double discountAmount;
  final Function(double amount) onDiscountChanged;

  const DiscountWidget({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    required this.onDiscountChanged,
  });

  @override
  State<DiscountWidget> createState() => _DiscountWidgetState();
}

class _DiscountWidgetState extends State<DiscountWidget> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.discountAmount.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(DiscountWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discountAmount != widget.discountAmount) {
      _amountController.text = widget.discountAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return sc.Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                sc.LucideIcons.percent,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'الخصم',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'مبلغ الخصم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: 'ل.س ',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0.0;
                    widget.onDiscountChanged(amount);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قيمة الخصم:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${widget.discountAmount.toStringAsFixed(2)} ل.س',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
