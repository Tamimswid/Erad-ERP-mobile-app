import 'package:erad/features/invoices/presentation/widgets/product_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../products/data/models/product.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../data/models/invoice_item.dart';
import '../bloc/invoice_cubit.dart';

class ProductAddWidget extends StatefulWidget {
  const ProductAddWidget({super.key});

  @override
  State<ProductAddWidget> createState() => _ProductAddWidgetState();
}

class _ProductAddWidgetState extends State<ProductAddWidget> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _searchFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _searchResults = [];
  ProductModel? _selectedProduct;
  List<InvoiceItem> _cachedItems = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductCubit>().getProducts();
      }
    });
  }

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
        context.read<InvoiceCubit>().addInvoiceItem(invoiceItem);

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

    if (name.isEmpty) {
      return;
    }

    ProductModel? existingProduct;
    try {
      existingProduct = _allProducts.firstWhere(
        (product) => product.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
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
    );

    context.read<InvoiceCubit>().addInvoiceItem(invoiceItem);

    setState(() {
      _searchController.clear();
      _quantityController.text = '1';
      _selectedProduct = null;
    });
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceCubit, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceFormUpdated) {
          setState(() {});
        }
      },
      child: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, productState) {
          if (productState is ProductsLoaded) {
            _allProducts = productState.products;
          }

          final invoiceCubit = context.read<InvoiceCubit>();
          final itemCount = invoiceCubit.invoiceItems.length;
          
          if (itemCount != _cachedItems.length) {
            _cachedItems = List.from(invoiceCubit.invoiceItems);
          }

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
                    _buildSectionTitle(
                      Icons.inventory_2_outlined,
                      'إضافة منتج',
                    ),
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
                        '${_cachedItems.length} منتج',
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
                    border: Border.all(
                      color: AppColors.border,
                    ),
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
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
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
                                constraints: const BoxConstraints(
                                  maxHeight: 180,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.border,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(
                                      AppConstants.borderRadius,
                                    ),
                                    bottomRight: Radius.circular(
                                      AppConstants.borderRadius,
                                    ),
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
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        child: Icon(
                                          Icons.inventory_2,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight:
                                              AppFonts.fontWeightSemiBold,
                                          color: AppColors.text,
                                          fontSize: AppFonts.fontSizeSmall,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${product.code} - ${product.salePrice.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()} (${product.unit})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: AppFonts.fontWeightMedium,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      onTap: () =>
                                          _onProductSelected(product),
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
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
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
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius,
                                    ),

                                  ),
                                  elevation: 0
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
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
                ProductListWidget(onItemRemoved: () {
                  setState(() {});
                }),
              ],
            ),
          ),
        );
      },
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
}













// 