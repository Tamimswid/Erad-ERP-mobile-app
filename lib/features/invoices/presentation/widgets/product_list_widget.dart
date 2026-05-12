import 'package:flutter/material.dart';
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
                      child: Text(
                        item.unitPrice.toStringAsFixed(0).toString()
,                        style: const TextStyle(
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
                        '${item.totalPrice.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
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

  void _removeItem(int index) {
    context.read<InvoiceCubit>().removeInvoiceItem(index);
    widget.onItemRemoved?.call();
  }
}