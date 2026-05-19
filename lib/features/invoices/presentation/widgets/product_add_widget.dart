import 'package:erad/features/invoices/presentation/widgets/product_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
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
  final _quantityController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _searchResults = [];
  ProductModel? _selectedProduct;
  List<InvoiceItem> _cachedItems = [];

  @override
  void initState() {
    super.initState();
    // _searchFocusNode.requestFocus();
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
        final invoiceCubit = context.read<InvoiceCubit>();
        final isSale = invoiceCubit.invoiceType == 'sale';
        final unitPrice = isSale ? _selectedProduct!.salePrice : _selectedProduct!.purchasePrice;
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
        invoiceCubit.addInvoiceItem(invoiceItem);

        setState(() {
          _searchController.clear();
        _quantityController.clear();
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
    final quantity = int.tryParse(_quantityController.text);

    if (name.isEmpty) {
      return;
    }

    if (quantity == null || quantity <= 0) {
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

    final invoiceCubit = context.read<InvoiceCubit>();
    final isSale = invoiceCubit.invoiceType == 'sale';
    final unitPrice = isSale ? existingProduct!.salePrice : existingProduct!.purchasePrice;

    final invoiceItem = InvoiceItem(
      measurement: existingProduct!.measurement ,
      
      unit: existingProduct.unit ,
      productId: existingProduct.id,
      productName: name,
      quantity: quantity,
      unitPrice: unitPrice,
      purchasePrice: existingProduct.purchasePrice,
      totalPrice: unitPrice * quantity,
    );

    invoiceCubit.addInvoiceItem(invoiceItem);

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

               
                    _buildMobileAddForm() ,


                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        'اسحب لليمين لحذف المنتج',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: AppFonts.fontSizeMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ProductListWidget(
                    onItemRemoved: () {
                      setState(() {});
                    },
                  ),
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
                    product.nameWithMeasurementUnit,
                    style: const TextStyle(
                      fontWeight: AppFonts.fontWeightSemiBold,
                      fontSize: AppFonts.fontSizeSmall,
                    ),
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
              child: ElevatedButton(
                onPressed: _onQuantitySubmitted,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(0),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  elevation: 0,
                ),
                child: const Text('إضافة'),
              ),
            ),
          ],
        ),
      ],
    );
  }


}













// 