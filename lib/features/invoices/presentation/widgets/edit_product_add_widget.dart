import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../products/data/models/product.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../data/models/invoice_item.dart';
import '../bloc/edit_invoice_cubit.dart';

class EditProductAddWidget extends StatefulWidget {
  const EditProductAddWidget({super.key});

  @override
  State<EditProductAddWidget> createState() => _EditProductAddWidgetState();
}

class _EditProductAddWidgetState extends State<EditProductAddWidget> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _searchFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _searchResults = [];
  ProductModel? _selectedProduct;

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _searchFocusNode.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedProduct = null;
      });
      return;
    }

    if (_allProducts.isEmpty) return;

    final results = _allProducts.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.code.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchResults = results.take(10).toList();
      _selectedProduct = null;
    });
  }

  void _onSearchSubmitted(String query) {
    if (_searchResults.isNotEmpty) {
      _onProductSelected(_searchResults.first);
    }
  }

  void _onProductSelected(ProductModel product) {
    setState(() {
      _selectedProduct = product;
      _searchResults = [];
    });
    _searchController.text = '${product.name} (${product.unit})';
    _quantityFocusNode.requestFocus();
  }

  void _onQuantitySubmitted() {
    if (_selectedProduct != null) {
      final quantity = int.tryParse(_quantityController.text);
      if (quantity != null && quantity > 0) {
        final invoiceItem = InvoiceItem.fromProduct(_selectedProduct!, quantity);
        context.read<EditInvoiceCubit>().addItem(invoiceItem);

        setState(() {
          _searchController.clear();
          _quantityController.text = '1';
          _selectedProduct = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    } else {
      _confirmAddProduct();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _confirmAddProduct() {
    var name = _searchController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (name.isEmpty) return;

    ProductModel? existingProduct;
    try {
      existingProduct = _allProducts.firstWhere(
        (product) => product.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      existingProduct = null;
    }

    if (existingProduct != null) {
      name = '${existingProduct.name} (${existingProduct.unit})';
    }

    final invoiceItem = InvoiceItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: existingProduct?.id ?? '',
      productName: name,
      quantity: quantity,
      unitPrice: existingProduct?.salePrice ?? 0,
      totalPrice: (existingProduct?.salePrice ?? 0) * quantity,
      unit: existingProduct?.unit ?? 'piece',
      createdAt: DateTime.now(),
    );

    context.read<EditInvoiceCubit>().addItem(invoiceItem);

    setState(() {
      _searchController.clear();
      _quantityController.text = '1';
      _selectedProduct = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, productState) {
        if (productState is ProductsLoaded) {
          _allProducts = productState.products;
        }

        return BlocBuilder<EditInvoiceCubit, EditInvoiceState>(
          builder: (context, state) {
            final items = state is EditInvoiceLoaded ? state.items : <InvoiceItem>[];
            
            return Card(
              elevation: AppConstants.cardElevation,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
                side: BorderSide(color: AppColors.border, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSectionTitle(Icons.inventory_2_outlined, 'المنتجات'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${items.length} منتج',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: AppFonts.fontWeightSemiBold,
                              fontSize: AppFonts.fontSizeSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اسم المنتج',
                                  style: const TextStyle(
                                    fontSize: AppFonts.fontSizeSmall,
                                    fontWeight: AppFonts.fontWeightMedium,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  decoration: InputDecoration(
                                    hintText: 'ابحث عن منتج أو اكتب اسم المنتج...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadius,
                                      ),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadius,
                                      ),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadius,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: _onSearchChanged,
                                  onSubmitted: _onSearchSubmitted,
                                ),

                                if (_searchResults.isNotEmpty)
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 180),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(AppConstants.borderRadius),
                                        bottomRight: Radius.circular(AppConstants.borderRadius),
                                      ),
                                      color: AppColors.surface,
                                      boxShadow: AppConstants.cardShadow,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _searchResults.length,
                                      itemBuilder: (context, index) {
                                        final product = _searchResults[index];
                                        return ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            child: Icon(Icons.inventory_2, color: AppColors.primary, size: 18),
                                          ),
                                          title: Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: AppFonts.fontWeightSemiBold,
                                              color: AppColors.text,
                                              fontSize: AppFonts.fontSizeSmall,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${product.code} - ${product.salePrice.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()} (${product.unit})',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          onTap: () => _onProductSelected(product),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الكمية',
                                  style: const TextStyle(
                                    fontSize: AppFonts.fontSizeSmall,
                                    fontWeight: AppFonts.fontWeightMedium,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _quantityController,
                                  focusNode: _quantityFocusNode,
                                  decoration: InputDecoration(
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
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onSubmitted: (_) => _onQuantitySubmitted(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  height: 35,
                                  child: ElevatedButton(
                                    onPressed: _confirmAddProduct,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.surface,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, size: 18),
                                        SizedBox(width: 4),
                                        Text('إضافة'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProductList(items),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(List<InvoiceItem> items) {
    if (items.isEmpty) {
      return SizedBox(
        height: 120,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 4, child: Text('المنتج', style: TextStyle(fontWeight: FontWeight.w500))),
                const Expanded(flex: 1, child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500))),
                const Expanded(flex: 2, child: Text('السعر', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w500))),
                const Expanded(flex: 2, child: Text('الإجمالي', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w500))),
                const SizedBox(width: 40),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? AppColors.surface : AppColors.background,
                border: index < items.length - 1 ? Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 0.5)) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(item.unit ?? '', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () => _showEditQuantityDialog(index, item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _showEditPriceDialog(index, item),
                      child: Text(
                        '${item.unitPrice.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.totalPrice.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => context.read<EditInvoiceCubit>().removeItem(index),
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showEditQuantityDialog(int index, InvoiceItem item) {
    final quantityController = TextEditingController(text: item.quantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الكمية'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'الكمية'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(quantityController.text);
              if (newQuantity != null && newQuantity > 0) {
                final updatedItem = InvoiceItem(
                  id: item.id,
                  productId: item.productId,
                  productName: item.productName,
                  quantity: newQuantity,
                  unitPrice: item.unitPrice,
                  discountAmount: item.discountAmount,
                  totalPrice: newQuantity * item.unitPrice,
                  unit: item.unit,
                  measurement: item.measurement,
                  createdAt: item.createdAt,
                );
                this.context.read<EditInvoiceCubit>().updateItem(index, updatedItem);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(int index, InvoiceItem item) {
    final priceController = TextEditingController(text: item.unitPrice.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل السعر'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'السعر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice > 0) {
                final updatedItem = InvoiceItem(
                  id: item.id,
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  unitPrice: newPrice,
                  discountAmount: item.discountAmount,
                  totalPrice: item.quantity * newPrice,
                  unit: item.unit,
                  measurement: item.measurement,
                  createdAt: item.createdAt,
                );
                this.context.read<EditInvoiceCubit>().updateItem(index, updatedItem);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}