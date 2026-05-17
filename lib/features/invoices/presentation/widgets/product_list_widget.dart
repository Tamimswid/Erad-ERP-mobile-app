import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
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
          return _buildEmptyState();
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      return _buildMobileProductList(items);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'المنتج',
                    style: TextStyle(
                      fontWeight: AppFonts.fontWeightMedium,
                      color: AppColors.text,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'الكمية',
                    style: TextStyle(
                      fontWeight: AppFonts.fontWeightMedium,
                      color: AppColors.text,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'السعر',
                    style: TextStyle(
                      fontWeight: AppFonts.fontWeightMedium,
                      color: AppColors.text,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'الإجمالي',
                    style: TextStyle(
                      fontWeight: AppFonts.fontWeightMedium,
                      color: AppColors.text,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
          ),
          
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
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onDismissed: (direction) {
                _removeItem(index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? AppColors.surface : AppColors.background,
                  border: index < items.length - 1 
                      ? Border(
                          bottom: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: AppFonts.fontWeightSemiBold,
                              color: AppColors.text,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            item.unit,
                            style: TextStyle(
                              fontWeight: AppFonts.fontWeightMedium,
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: AppFonts.fontWeightSemiBold,
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildEditablePrice(index, item),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${NumberFormatter.format(item.totalPrice)} ${NumberFormatter.getCurrencySymbol()}',
                        style: const TextStyle(
                          fontWeight: AppFonts.fontWeightBold,
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileProductList(List<InvoiceItem> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Dismissible(
          key: Key('product_${item.productId}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 24,
            ),
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
                        item.productName,
                        style: const TextStyle(
                          fontWeight: AppFonts.fontWeightSemiBold,
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${NumberFormatter.format(item.totalPrice)} ${NumberFormatter.getCurrencySymbol()}',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الكمية: ${item.quantity}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'السعر: ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
      }).toList(),
    );
  }

  Widget _buildEditablePrice(int index, InvoiceItem item, {bool isMobile = false}) {
    if (!_priceControllers.containsKey(index)) {
      _priceControllers[index] = TextEditingController(
        text: item.unitPrice.toStringAsFixed(2),
      );
    }

    final isEditing = _editingStates[index] ?? false;

    if (isEditing) {
      return TextField(
        controller: _priceControllers[index],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Text(
          NumberFormatter.format(item.unitPrice),
          style: const TextStyle(
            fontWeight: AppFonts.fontWeightMedium,
            color: AppColors.text,
            fontSize: 11,
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