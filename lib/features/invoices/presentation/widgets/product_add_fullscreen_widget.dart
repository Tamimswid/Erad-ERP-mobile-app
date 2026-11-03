import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../products/data/models/product.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../data/models/invoice_item.dart';
import '../bloc/invoice_cubit.dart';

class ProductAddFullscreenPage extends StatefulWidget {
  const ProductAddFullscreenPage({super.key});

  @override
  State<ProductAddFullscreenPage> createState() =>
      _ProductAddFullscreenPageState();
}

class _ProductAddFullscreenPageState extends State<ProductAddFullscreenPage> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _searchFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _searchResults = [];
  ProductModel? _selectedProduct;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final productState = context.read<ProductCubit>().state;
        if (productState is ProductsLoaded) {
          setState(() {
            _allProducts = productState.products;
          });
        }
        _searchFocusNode.requestFocus();
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
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    if (_allProducts.isEmpty) return;

    final results = _allProducts.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.code.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchResults = results;
      _selectedProduct = null;
    });
  }

  void _onProductSelected(ProductModel product) {
    setState(() {
      _selectedProduct = product;
      _searchController.text = '${product.name} (${product.unit})';
      _searchResults = [];
    });
    _quantityFocusNode.requestFocus();
  }

  void _addProduct() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) return;

    ProductModel? product = _selectedProduct;

    if (product == null) {
      final name = _searchController.text.trim();
      if (name.isEmpty) return;
      try {
        product = _allProducts.firstWhere(
          (p) => p.name.toLowerCase() == name.toLowerCase(),
        );
      } catch (_) {
        return;
      }
    }

    final invoiceCubit = context.read<InvoiceCubit>();
    final isSale = invoiceCubit.invoiceType == 'sale';
    final unitPrice = isSale ? product.salePrice : product.purchasePrice;

    final invoiceItem = InvoiceItem(
      measurement: product.measurement,
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: unitPrice,
      purchasePrice: product.purchasePrice,
      totalPrice: unitPrice * quantity,
      unit: product.unit,
    );
    invoiceCubit.addInvoiceItem(invoiceItem);

    setState(() {
      _searchController.clear();
      _quantityController.text = '1';
      _selectedProduct = null;
      _isSearching = false;
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return sc.Scaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            _buildSearchAndAddRow(),
            const Divider(height: 1),
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : _buildAddedProducts(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(sc.LucideIcons.arrowRight, color: AppColors.text),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            'إضافة منتج',
            style: const TextStyle(
              fontSize: AppFonts.fontSizeXLarge,
              fontWeight: AppFonts.fontWeightBold,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          BlocBuilder<InvoiceCubit, InvoiceState>(
            builder: (context, state) {
              final count = context.read<InvoiceCubit>().invoiceItems.length;
              return Container(
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
                  '$count منتج',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    fontSize: AppFonts.fontSizeSmall,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildSearchAndAddRow() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: const Icon(
                  sc.LucideIcons.search,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
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
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _quantityFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _quantityController,
              focusNode: _quantityFocusNode,
              decoration: InputDecoration(
                labelText: 'الكمية',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
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
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _addProduct(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: sc.Button(
              style: sc.ButtonStyle.primary(),
              onPressed: _addProduct,
              child: const Text('إضافة'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sc.LucideIcons.search,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFonts.fontSizeMedium,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 12, endIndent: 12),
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        final isSelected = _selectedProduct?.id == product.id;
        return ListTile(
          selected: isSelected,
          selectedTileColor: AppColors.muted,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          title: Text(
            product.nameWithMeasurementUnit,
            style: const TextStyle(
              fontWeight: AppFonts.fontWeightSemiBold,
              fontSize: AppFonts.fontSizeMedium,
            ),
          ),
          subtitle: Text(
            '${NumberFormatter.format(product.salePrice)} ${NumberFormatter.getCurrencySymbol()}',
            style: const TextStyle(
              fontSize: AppFonts.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: isSelected
              ? const Icon(
                  sc.LucideIcons.circleCheck,
                  color: AppColors.primary,
                  size: 22,
                )
              : const Icon(
                  sc.LucideIcons.circlePlus,
                  color: AppColors.primary,
                  size: 22,
                ),
          onTap: () => _onProductSelected(product),
        );
      },
    );
  }

  Widget _buildAddedProducts() {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        final items = context.read<InvoiceCubit>().invoiceItems;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sc.LucideIcons.package,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 16),
                Text(
                  'لم تتم إضافة منتجات بعد',
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeLarge,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ابحث عن منتج وأضفه من الأعلى',
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeSmall,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    'المنتجات المضافة',
                    style: const TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: AppFonts.fontWeightBold,
                        fontSize: AppFonts.fontSizeSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Dismissible(
                    key: Key('fs_item_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        sc.LucideIcons.trash2,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    onDismissed: (_) {
                      context.read<InvoiceCubit>().removeInvoiceItem(index);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nameWithMeasurementUnit,
                                  style: const TextStyle(
                                    fontWeight: AppFonts.fontWeightSemiBold,
                                    color: AppColors.text,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                       'السعر: ${NumberFormatter.format(item.unitPrice?.toDouble() ?? 0.0)} ${NumberFormatter.getCurrencySymbol()}',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                             '${NumberFormatter.format(item.totalPrice?.toDouble() ?? 0.0)} ${NumberFormatter.getCurrencySymbol()}',
                            style: const TextStyle(
                              fontWeight: AppFonts.fontWeightBold,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
