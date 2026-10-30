import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/invoice_item.dart';
import '../bloc/invoice_cubit.dart';

class ProductListWidget extends StatefulWidget {
  final VoidCallback? onItemRemoved;

  const ProductListWidget({super.key, this.onItemRemoved});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, bool> _editingStates = {};
  int _previousItemCount = 0;

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        final items = context.read<InvoiceCubit>().invoiceItems;

        if (items.isEmpty) {
          _priceControllers.clear();
          _editingStates.clear();
          _previousItemCount = 0;
          return _buildEmptyState();
        }

        if (items.length != _previousItemCount) {
          _priceControllers.clear();
          _editingStates.clear();
          _previousItemCount = items.length;
        }

        return _buildProductList(items);
      },
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'لم تتم إضافة منتجات بعد',
            style: TextStyle(
              fontSize: AppFonts.fontSizeSmall,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<InvoiceItem> items) {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Dismissible(
            key: Key('product_${item.productId}_$index'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: AppColors.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white, size: 24),
            ),
            onDismissed: (direction) {
              _removeItem(index);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nameWithMeasurementUnit,
                          style: const TextStyle(
                            fontWeight: AppFonts.fontWeightSemiBold,
                            color: AppColors.text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '×${item.quantity}',
                          style: const TextStyle(
                            fontWeight: AppFonts.fontWeightBold,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                         '${AppUtils.formatNumber(item.totalPrice?.toDouble() ?? 0.0)} ${NumberFormatter.getCurrencySymbol()}',
                        style: const TextStyle(
                          fontWeight: AppFonts.fontWeightBold,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'السعر: ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 36,
                        child: _buildEditablePrice(index, item, isMobile: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length} منتج',
                style: TextStyle(
                  fontWeight: AppFonts.fontWeightSemiBold,
                  fontSize: AppFonts.fontSizeSmall,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditablePrice(
    int index,
    InvoiceItem item, {
    bool isMobile = false,
  }) {
    if (!_priceControllers.containsKey(index)) {
      _priceControllers[index] = TextEditingController(
        text: item.unitPrice?.toStringAsFixed(2) ?? '0.00',
      );
    }

    final isEditing = _editingStates[index] ?? false;

    if (isEditing) {
      return TextField(
        controller: _priceControllers[index],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        onSubmitted: (value) {
          _updatePrice(index, value);
        },
        onTapOutside: (_) {
          _updatePrice(index, _priceControllers[index]!.text);
        },
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _editingStates[index] = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Text(
          NumberFormatter.format(item.unitPrice?.toDouble() ?? 0.0),
          style: const TextStyle(
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
            fontSize: 14,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  void _updatePrice(int index, String value) {
    final price = double.tryParse(value);
    if (price != null && price >= 0) {
      context.read<InvoiceCubit>().updateItemPrice(index, price);
    }
    setState(() {
      _editingStates[index] = false;
      if (_priceControllers[index] != null) {
        _priceControllers[index]!.text = price?.toStringAsFixed(2) ?? '0';
      }
    });
  }

  void _removeItem(int index) {
    _priceControllers.remove(index);
    _editingStates.remove(index);
    context.read<InvoiceCubit>().removeInvoiceItem(index);
    widget.onItemRemoved?.call();
  }
}
