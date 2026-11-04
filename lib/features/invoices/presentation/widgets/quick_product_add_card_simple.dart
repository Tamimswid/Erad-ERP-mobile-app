import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/data/models/product.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../data/models/invoice_item.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class QuickProductAddCardSimple extends StatefulWidget {
  final List<InvoiceItem> items;
  final Function(InvoiceItem) onItemAdded;
  final Function(InvoiceItem)? onItemRemoved;
  final Function(List<InvoiceItem>)? onItemsChanged;

  const QuickProductAddCardSimple({
    super.key,
    required this.items,
    required this.onItemAdded,
    this.onItemRemoved,
    this.onItemsChanged,
  });

  @override
  State<QuickProductAddCardSimple> createState() =>
      _QuickProductAddCardSimpleState();
}

class _QuickProductAddCardSimpleState extends State<QuickProductAddCardSimple> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _searchFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _searchResults = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;

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
    print(
      '🔍 Searching for: "$query" with ${_allProducts.length} products available',
    );

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedProduct = null;
      });
      return;
    }

    if (_allProducts.isEmpty) {
      print('⚠️ No products available for search');
      return;
    }

    final results = _allProducts.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    print('🎯 Found ${results.length} matching products');

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

    _searchController.text = product.name;
    _quantityFocusNode.requestFocus();
  }

  void _onQuantitySubmitted() {
    final quantity = int.tryParse(_quantityController.text);
    if (_selectedProduct != null && quantity != null && quantity > 0) {
      final invoiceItem = InvoiceItem.fromProduct(_selectedProduct!, quantity);
      widget.onItemAdded(invoiceItem);

      // Reset form
      _searchController.clear();
      _quantityController.text = '1';
      _selectedProduct = null;
      _searchFocusNode.requestFocus();
    }
  }

  void _removeItem(InvoiceItem item) {
    if (widget.onItemRemoved != null) {
      widget.onItemRemoved!(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          _isLoading = true;
          _errorMessage = null;
        } else if (state is ProductsLoaded) {
          _isLoading = false;
          _errorMessage = null;
          _allProducts = state.products;
        } else if (state is ProductError) {
          _isLoading = false;
          _errorMessage = state.message;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة منتج سريع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.24),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sc.LucideIcons.circleAlert,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(sc.LucideIcons.refreshCw),
                          onPressed: () =>
                              context.read<ProductCubit>().getProducts(),
                        ),
                      ],
                    ),
                  ),

                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Search and Quantity Row
                if (!_isLoading)
                  Row(
                    children: [
                      // Product Search Field
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                labelText: 'بحث المنتج',
                                hintText: 'اكتب اسم المنتج أو الكود...',
                                prefixIcon: const Icon(sc.LucideIcons.search),
                                border: const OutlineInputBorder(),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(sc.LucideIcons.x),
                                        onPressed: () {
                                          _searchController.clear();
                                          _selectedProduct = null;
                                          _searchResults = [];
                                          _searchFocusNode.requestFocus();
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: _onSearchChanged,
                              onSubmitted: _onSearchSubmitted,
                            ),

                            // Search Results Dropdown
                            if (_searchResults.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.muted,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          sc.LucideIcons.keyboard,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'اضغط ENTER للمنتج الأول أو اختر منتج',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 250,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                      color: AppColors.surface,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.text.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _searchResults.length,
                                      itemBuilder: (context, index) {
                                        final product = _searchResults[index];
                                        final isFirst = index == 0;
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isFirst
                                                ? AppColors.muted
                                                : Colors.transparent,
                                            border: isFirst
                                                ? Border(
                                                    top: BorderSide(
                                                      color: AppColors.border,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            leading: CircleAvatar(
                                              backgroundColor: AppColors.muted,
                                              child: Icon(
                                                sc.LucideIcons.package,
                                                color: AppColors.textSecondary,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: isFirst
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isFirst
                                                    ? AppColors.textSecondary
                                                    : AppColors.text,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'السعر: ${product.salePrice.toStringAsFixed(2)} ل.س',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: isFirst
                                                ? Icon(
                                                    sc
                                                        .LucideIcons
                                                        .cornerDownLeft,
                                                    color:
                                                        AppColors.textSecondary,
                                                    size: 16,
                                                  )
                                                : null,
                                            onTap: () =>
                                                _onProductSelected(product),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Quantity Field
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _quantityController,
                          focusNode: _quantityFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'الكمية',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(sc.LucideIcons.listOrdered),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onSubmitted: (_) => _onQuantitySubmitted(),
                        ),
                      ),
                    ],
                  ),

                if (!_isLoading) const SizedBox(height: 24),

                // Excel-like Table
                if (!_isLoading) _buildInvoiceTable(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceTable() {
    if (widget.items.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'لم تتم إضافة منتجات بعد',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.muted,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'كود المنتج',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'اسم المنتج',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'الكمية',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'سعر الوحدة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'الإجمالي',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? AppColors.surface : AppColors.muted,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.productName ?? 'null_data'),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      (item.quantity ?? 0).toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      (item.unitPrice ?? 0.0).toStringAsFixed(2),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      (item.totalPrice ?? 0.0).toStringAsFixed(2),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            sc.LucideIcons.trash2,
                            size: 18,
                            color: AppColors.error,
                          ),
                          onPressed: () => _removeItem(item),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Total Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.muted,
              border: Border(top: BorderSide(color: AppColors.textSecondary)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 6,
                  child: Text(
                    'الإجمالي:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.items
                        .fold<double>(
                          0,
                          (sum, item) => sum + (item.totalPrice ?? 0.0),
                        )
                        .toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Expanded(flex: 1, child: SizedBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
