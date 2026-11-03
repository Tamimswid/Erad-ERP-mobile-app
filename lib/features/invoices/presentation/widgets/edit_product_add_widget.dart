import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
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
  final Map<int, TextEditingController> _priceControllers = {};

  List<ProductModel> _allProducts = [];
  List<ProductModel> _searchResults = [];
  ProductModel? _selectedProduct;

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _searchFocusNode.dispose();
    _quantityFocusNode.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
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
        final editCubit = context.read<EditInvoiceCubit>();
        final unitPrice = editCubit.isSales ? _selectedProduct!.salePrice : _selectedProduct!.purchasePrice;
        final invoiceItem = InvoiceItem(
          measurement: _selectedProduct!.measurement,
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.name,
          quantity: quantity,
          unitPrice: unitPrice,
          purchasePrice: _selectedProduct!.purchasePrice,
          totalPrice: unitPrice * quantity,
          unit: _selectedProduct!.unit,
        );
        editCubit.addItem(invoiceItem);

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

    final editCubit = context.read<EditInvoiceCubit>();
    final unitPrice = editCubit.isSales 
        ? (existingProduct?.salePrice ?? 0) 
        : (existingProduct?.purchasePrice ?? 0);

    final invoiceItem = InvoiceItem(
      
      productId: existingProduct?.id ?? '',
      productName: name,
      quantity: quantity,
      unitPrice: unitPrice,
      purchasePrice: existingProduct?.purchasePrice ?? 0,
      totalPrice: unitPrice * quantity,
      unit: existingProduct!.unit ,
      measurement: existingProduct.measurement,
      createdAt: DateTime.now(),
    );

    editCubit.addItem(invoiceItem);

    setState(() {
      _searchController.clear();
      _quantityController.text = '1';
      _selectedProduct = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, productState) {
        if (productState is ProductsLoaded) {
          _allProducts = productState.products;
        }

        return BlocBuilder<EditInvoiceCubit, EditInvoiceState>(
          builder: (context, state) {
            final items = state is EditInvoiceLoaded ? state.items : <InvoiceItem>[];
            
            return sc.Card(
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSectionTitle(sc.LucideIcons.package, 'المنتجات'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            '${items.length} منتج',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: AppFonts.fontWeightSemiBold,
                              fontSize: AppFonts.fontSizeSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    if (isMobile)
                      _buildMobileAddForm()
                    else
                      _buildDesktopAddForm(),

                    const SizedBox(height: 16),
                    _buildProductList(items),
                  ],
                ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileAddForm() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            labelText: 'اسم المنتج',
            hintText: 'ابحث عن منتج أو اكتب اسم المنتج...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
        ),
        if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              color: AppColors.surface,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: AppFonts.fontWeightSemiBold,
                      fontSize: AppFonts.fontSizeSmall,
                    ),
                  ),
                  subtitle: Text(
                    '${product.salePrice.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()} (${product.unit})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _onProductSelected(product),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                focusNode: _quantityFocusNode,
                decoration: InputDecoration(
                  labelText: 'الكمية',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _onQuantitySubmitted(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              height: 48,
              child: sc.Button(
                style: sc.ButtonStyle.primary(),
                onPressed: _confirmAddProduct,
                child: const Text('إضافة'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
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
                            backgroundColor: AppColors.surface,
                            child: Icon(sc.LucideIcons.package, color: AppColors.text, size: 18),
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
                  child: sc.Button(
                    style: sc.ButtonStyle.primary(),
                    onPressed: _confirmAddProduct,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(sc.LucideIcons.plus, size: 18),
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
            Icon(sc.LucideIcons.package, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
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

    for (int i = 0; i < items.length; i++) {
      if (!_priceControllers.containsKey(i)) {
        _priceControllers[i] = TextEditingController(text: items[i].unitPrice?.toStringAsFixed(2) ?? "0.00");
      }
    }

    _priceControllers.removeWhere((key, _) => key >= items.length);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName??'', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(item.unit ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(sc.LucideIcons.trash2, size: 20, color: AppColors.error),
                    onPressed: () {
                      _priceControllers.remove(index);
                      context.read<EditInvoiceCubit>().removeItem(index);
                    },
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
                        Text('الكمية', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showEditQuantityDialog(index, item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.muted,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                                const SizedBox(width: 4),
                                const Icon(sc.LucideIcons.pencil, size: 14, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السعر', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _priceControllers[index],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                            onChanged: (value) {
                              final newPrice = double.tryParse(value);
                              if (newPrice != null && newPrice >= 0) {
                                final updatedItem = InvoiceItem(
                                  id: item.id,
                                  productId: item.productId,
                                   productName: item.productName ?? 'null_data',
                                   quantity: item.quantity ?? 0,
                                   unitPrice: newPrice,
                                   purchasePrice: item.purchasePrice ?? 0.0,
                                   discountAmount: item.discountAmount ?? 0.0,
                                   totalPrice: (item.quantity?.toDouble() ?? 0.0) * newPrice,
                                   unit: item.unit ?? 'null_data',
                                   measurement: item.measurement ?? 'null_data',
                                   createdAt: item.createdAt,
                                );
                                context.read<EditInvoiceCubit>().updateItem(index, updatedItem);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الإجمالي', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          '${item.totalPrice?.toStringAsFixed(2) ?? "0.00"} ${NumberFormatter.getCurrencySymbol()}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditQuantityDialog(int index, InvoiceItem item) {
    final quantityController = TextEditingController(text: item.quantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الكمية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'الكمية'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  sc.Button(
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  sc.Button(
                    style: sc.ButtonStyle.primary(),
                    onPressed: () {
                      final newQuantity = int.tryParse(quantityController.text);
                      if (newQuantity != null && newQuantity > 0) {
                        final updatedItem = InvoiceItem(
                          id: item.id,
                          productId: item.productId,
                           productName: item.productName ?? 'null_data',
                           quantity: newQuantity,
                           unitPrice: item.unitPrice ?? 0.0,
                           purchasePrice: item.purchasePrice ?? 0.0,
                           discountAmount: item.discountAmount ?? 0.0,
                           totalPrice: newQuantity.toDouble() * (item.unitPrice ?? 0.0),
                           unit: item.unit ?? 'null_data',
                           measurement: item.measurement ?? 'null_data',
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
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPriceDialog(int index, InvoiceItem item) {
    final priceController = TextEditingController(text: item.unitPrice?.toStringAsFixed(2) ?? "0.00");
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل السعر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'السعر'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  sc.Button(
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  sc.Button(
                    style: sc.ButtonStyle.primary(),
                    onPressed: () {
                      final newPrice = double.tryParse(priceController.text);
                      if (newPrice != null && newPrice > 0) {
                        final updatedItem = InvoiceItem(
                          id: item.id,
                          productId: item.productId,
                           productName: item.productName ?? 'null_data',
                           quantity: item.quantity ?? 0,
                           unitPrice: newPrice,
                           purchasePrice: item.purchasePrice ?? 0.0,
                           discountAmount: item.discountAmount ?? 0.0,
                           totalPrice: (item.quantity?.toDouble() ?? 0.0) * newPrice,
                           unit: item.unit ?? 'null_data',
                           measurement: item.measurement ?? 'null_data',
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
            ],
          ),
        ),
      ),
    );
  }
}