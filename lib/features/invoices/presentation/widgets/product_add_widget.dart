import 'dart:async';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:erad/features/invoices/presentation/widgets/product_list_widget.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/presentation/bloc/product_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class ProductAddWidget extends StatefulWidget {
  final FocusNode searchFocusNode;

  const ProductAddWidget({super.key, required this.searchFocusNode});

  @override
  State<ProductAddWidget> createState() => _ProductAddWidgetState();
}

class _ProductAddWidgetState extends State<ProductAddWidget> {
  static const _searchDebounce = Duration(milliseconds: 300);
  static const _maxSuggestions = 8;

  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _quantityFocusNode = FocusNode();
  Timer? _debounce;

  String _query = '';
  bool _isSearching = false;
  ProductModel? _pendingProduct;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  List<ProductModel> get _results {
    if (_query.isEmpty) return const [];
    final state = context.read<ProductCubit>().state;
    if (state is! ProductsLoaded) return const [];
    return state.products.take(_maxSuggestions).toList();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    setState(() {
      _query = query;
      _pendingProduct = null;
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) return;

    _debounce = Timer(_searchDebounce, () async {
      if (!mounted) return;
      await context.read<ProductCubit>().searchProducts(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() => _isSearching = false);
    });
  }

  Future<void> _submitSearch() async {
    if (_pendingProduct != null) {
      _quantityFocusNode.requestFocus();
      return;
    }

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _quantityFocusNode.requestFocus();
      return;
    }

    _debounce?.cancel();
    var results = _results;

    if (results.isEmpty) {
      setState(() => _isSearching = true);
      await context.read<ProductCubit>().searchProducts(query);
      if (!mounted || _searchController.text.trim() != query) return;
      results = _results;
      setState(() => _isSearching = false);
    }

    if (results.isEmpty) {
      _showMessage('لم يتم العثور على المنتج');
      return;
    }

    _selectProduct(results.first);
  }

  void _selectProduct(ProductModel product) {
    _debounce?.cancel();
    _searchController.text = product.name;
    setState(() {
      _pendingProduct = product;
      _query = '';
      _isSearching = false;
    });
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
    );
    _quantityFocusNode.requestFocus();
  }

  void _confirmPendingProduct() {
    final product = _pendingProduct;
    if (product == null) return;
    _addProduct(product);
  }

  void _addProduct(ProductModel product) {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      _showMessage('أدخل كمية صحيحة');
      return;
    }

    final cubit = context.read<InvoiceCubit>();
    final isSale = cubit.invoiceType == 'sale';
    final unitPrice = isSale ? product.salePrice : product.purchasePrice;

    cubit.addInvoiceItem(
      InvoiceItem(
        measurement: product.measurement,
        unit: product.unit,
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: unitPrice,
        purchasePrice: product.purchasePrice,
        totalPrice: unitPrice * quantity,
      ),
    );

    _debounce?.cancel();
    _searchController.clear();
    _quantityController.text = '1';
    setState(() {
      _pendingProduct = null;
      _query = '';
      _isSearching = false;
    });
    widget.searchFocusNode.requestFocus();
  }

  void _resetInputs() {
    _debounce?.cancel();
    _searchController.clear();
    _quantityController.text = '1';
    if (!mounted) return;
    setState(() {
      _pendingProduct = null;
      _query = '';
      _isSearching = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceCubit, InvoiceState>(
      listenWhen: (previous, current) =>
          current is InvoiceFormUpdated && current.updateType == 'clearAll',
      listener: (context, state) => _resetInputs(),
      child: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, invoiceState) {
          final itemCount = context.read<InvoiceCubit>().invoiceItems.length;

          return sc.Card(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(itemCount),
                const SizedBox(height: AppConstants.spacingMd),
                _buildInputRow(),
                BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, productState) =>
                      _buildSuggestions(productState),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      sc.LucideIcons.info,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _pendingProduct == null
                            ? 'ابحث عن منتج واختره، ثم أدخل الكمية واضغط Enter'
                            : 'أدخل الكمية ثم اضغط Enter لإضافة ${_pendingProduct!.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ProductListWidget(
                  onItemRemoved: () {
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int itemCount) {
    return Row(
      children: [
        const Text(
          'المنتجات',
          style: TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            '$itemCount منتج',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: AppFonts.fontWeightSemiBold,
              fontSize: AppFonts.fontSizeSmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: widget.searchFocusNode,
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            onSubmitted: (_) => _submitSearch(),
            decoration:
                _inputDecoration(
                  hint: 'اسم المنتج',
                  icon: sc.LucideIcons.search,
                ).copyWith(
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: TextField(
            controller: _quantityController,
            focusNode: _quantityFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onTap: () => _quantityController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _quantityController.text.length,
            ),
            onSubmitted: (_) => _confirmPendingProduct(),
            decoration: _inputDecoration(hint: 'الكمية'),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppColors.textSecondary, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildSuggestions(ProductState productState) {
    if (_query.isEmpty) return const SizedBox.shrink();

    final results = _results;

    if (results.isEmpty) {
      if (_isSearching) return const SizedBox(height: 4);
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          productState is ProductError
              ? productState.message
              : 'لا توجد نتائج مطابقة',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    final isSale = context.read<InvoiceCubit>().invoiceType == 'sale';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: results.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = results[index];
          final price = isSale ? product.salePrice : product.purchasePrice;

          return InkWell(
            onTap: () => _selectProduct(product),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nameWithMeasurementUnit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: AppFonts.fontWeightMedium,
                            fontSize: AppFonts.fontSizeSmall,
                            color: AppColors.text,
                          ),
                        ),
                        if (product.code.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            product.code,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${NumberFormatter.format(price)} ${NumberFormatter.getCurrencySymbol()}',
                    style: const TextStyle(
                      fontWeight: AppFonts.fontWeightSemiBold,
                      fontSize: AppFonts.fontSizeSmall,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
