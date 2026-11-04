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
  static const _maxSuggestions = 10;

  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _searchFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  final Map<String, TextEditingController> _priceControllers = {};

  List<ProductModel> _allProducts = const [];
  String _query = '';
  ProductModel? _pendingProduct;

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

  List<ProductModel> _matches() {
    final query = _query.toLowerCase();
    if (query.isEmpty) return const [];
    return _allProducts
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.code.toLowerCase().contains(query),
        )
        .take(_maxSuggestions)
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.trim();
      _pendingProduct = null;
    });
  }

  void _onSearchSubmitted() {
    if (_pendingProduct != null) {
      _quantityFocusNode.requestFocus();
      return;
    }
    final matches = _matches();
    if (matches.isEmpty) {
      _showMessage('لم يتم العثور على المنتج');
      return;
    }
    _selectProduct(matches.first);
  }

  void _selectProduct(ProductModel product) {
    _searchController.text = product.name;
    setState(() {
      _pendingProduct = product;
      _query = '';
    });
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
    );
    _quantityFocusNode.requestFocus();
  }

  void _confirmAdd() {
    final product = _pendingProduct;
    if (product == null) {
      _showMessage('اختر منتجاً من نتائج البحث أولاً');
      _searchFocusNode.requestFocus();
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      _showMessage('أدخل كمية صحيحة');
      return;
    }

    final cubit = context.read<EditInvoiceCubit>();
    final unitPrice = cubit.isSales ? product.salePrice : product.purchasePrice;

    cubit.addItem(
      InvoiceItem(
        measurement: product.measurement,
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: unitPrice,
        purchasePrice: product.purchasePrice,
        totalPrice: unitPrice * quantity,
        unit: product.unit,
        createdAt: DateTime.now(),
      ),
    );

    setState(() {
      _searchController.clear();
      _quantityController.text = '1';
      _pendingProduct = null;
      _query = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
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

  String _itemKey(InvoiceItem item) {
    final id = item.id?.trim() ?? '';
    if (id.isNotEmpty) return id;
    final createdAt = item.createdAt?.microsecondsSinceEpoch ?? 0;
    return '${item.productId}_$createdAt';
  }

  String _uniqueKey(String base, Set<String> used) {
    if (used.add(base)) return base;
    var suffix = 1;
    while (!used.add('$base#$suffix')) {
      suffix++;
    }
    return '$base#$suffix';
  }

  void _disposeControllerLater(TextEditingController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, productState) {
        if (productState is! ProductsLoaded) return;
        _allProducts = productState.products;
        context.read<EditInvoiceCubit>().setProductCatalog(
          productState.products,
        );
        // Re-run the filter: the list may arrive after the user started typing.
        if (_query.isNotEmpty && mounted) setState(() {});
      },
      builder: (context, productState) {
        if (productState is ProductsLoaded) {
          _allProducts = productState.products;
        }

        return BlocBuilder<EditInvoiceCubit, EditInvoiceState>(
          builder: (context, state) {
            final cubit = context.read<EditInvoiceCubit>();
            final items = state is EditInvoiceLoaded
                ? state.items
                : const <InvoiceItem>[];
            final isMobile = MediaQuery.of(context).size.width < 600;

            return sc.Card(
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(items.length),
                  const SizedBox(height: AppConstants.spacingMd),
                  if (isMobile)
                    _buildMobileForm(productState)
                  else
                    _buildDesktopForm(productState),
                  const SizedBox(height: 12),
                  _buildHint(),
                  const SizedBox(height: 12),
                  _buildProductList(items, cubit),
                ],
              ),
            );
          },
        );
      },
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

  Widget _buildHint() {
    final product = _pendingProduct;
    final message = product == null
        ? 'ابحث عن منتج واختره، ثم أدخل الكمية واضغط Enter'
        : 'أدخل الكمية ثم اضغط Enter لإضافة ${product.name}';

    return Row(
      children: [
        const Icon(
          sc.LucideIcons.info,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileForm(ProductState productState) {
    return Column(
      children: [
        _buildSearchField(productState),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuantityField()),
            const SizedBox(width: 12),
            SizedBox(width: 100, height: 48, child: _buildAddButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopForm(ProductState productState) {
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
          Expanded(flex: 7, child: _buildSearchField(productState)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('الكمية'),
                const SizedBox(height: 6),
                _buildQuantityField(),
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
                  height: 42,
                  child: _buildAddButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: AppFonts.fontSizeSmall,
        fontWeight: AppFonts.fontWeightMedium,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSearchField(ProductState productState) {
    final matches = _matches();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.of(context).size.width >= 600) ...[
          _fieldLabel('اسم المنتج'),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _onSearchSubmitted(),
          decoration: _inputDecoration(
            hint: 'ابحث عن منتج أو اكتب اسم المنتج...',
          ),
        ),
        if (_query.isNotEmpty) _buildSuggestions(productState, matches),
      ],
    );
  }

  Widget _buildSuggestions(
    ProductState productState,
    List<ProductModel> matches,
  ) {
    if (matches.isEmpty) {
      final isError = productState is ProductError;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          isError
              ? productState.message
              : productState is ProductsLoaded
              ? 'لا توجد نتائج مطابقة'
              : 'جاري تحميل المنتجات...',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    final isSale = context.read<EditInvoiceCubit>().isSales;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: matches.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = matches[index];
          final price = isSale ? product.salePrice : product.purchasePrice;
          final meta = product.code;

          return ListTile(
            dense: true,
            title: Text(
              product.nameWithMeasurementUnit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: AppFonts.fontWeightMedium,
                fontSize: AppFonts.fontSizeSmall,
                color: AppColors.text,
              ),
            ),
            subtitle: meta.isEmpty
                ? null
                : Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
            trailing: Text(
              '${NumberFormatter.format(price)} ${NumberFormatter.getCurrencySymbol()}',
              style: const TextStyle(
                fontWeight: AppFonts.fontWeightSemiBold,
                fontSize: AppFonts.fontSizeSmall,
                color: AppColors.text,
              ),
            ),
            onTap: () => _selectProduct(product),
          );
        },
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextField(
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
      onSubmitted: (_) => _confirmAdd(),
      decoration: _inputDecoration(hint: 'الكمية'),
    );
  }

  Widget _buildAddButton() {
    return sc.Button(
      alignment: Alignment.center,
      style: sc.ButtonStyle.primary(),
      onPressed: _confirmAdd,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(sc.LucideIcons.plus, size: 18),
          SizedBox(width: 4),
          Text('إضافة'),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }

  Widget _buildProductList(List<InvoiceItem> items, EditInvoiceCubit cubit) {
    if (items.isEmpty) {
      return SizedBox(
        height: 120,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sc.LucideIcons.package,
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

    final keys = <String>{};
    final itemKeys = <String>[];
    for (final item in items) {
      final key = _uniqueKey(_itemKey(item), keys);
      itemKeys.add(key);
      _priceControllers.putIfAbsent(
        key,
        () => TextEditingController(
          text: item.unitPrice?.toStringAsFixed(2) ?? '0.00',
        ),
      );
    }
    _priceControllers.removeWhere((key, controller) {
      if (keys.contains(key)) return false;
      _disposeControllerLater(controller);
      return true;
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final key = itemKeys[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
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
                        Text(
                          cubit.displayLabel(item),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      sc.LucideIcons.trash2,
                      size: 20,
                      color: AppColors.error,
                    ),
                    onPressed: () {
                      final controller = _priceControllers.remove(key);
                      if (controller != null) {
                        _disposeControllerLater(controller);
                      }
                      cubit.removeItem(index);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildItemField(
                      label: 'الكمية',
                      child: GestureDetector(
                        onTap: () => _showEditQuantityDialog(index, item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${item.quantity ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                sc.LucideIcons.pencil,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildItemField(
                      label: 'السعر',
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _priceControllers[key],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.text,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            final newPrice = double.tryParse(value);
                            if (newPrice == null || newPrice < 0) return;
                            final quantity = (item.quantity ?? 0).toDouble();
                            cubit.updateItem(
                              index,
                              item.copyWith(
                                unitPrice: newPrice,
                                totalPrice: quantity * newPrice,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildItemField(
                      label: 'الإجمالي',
                      child: Text(
                        '${NumberFormatter.format(item.totalPrice ?? 0)} ${NumberFormatter.getCurrencySymbol()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
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

  Widget _buildItemField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  void _showEditQuantityDialog(int index, InvoiceItem item) {
    final quantityController = TextEditingController(
      text: '${item.quantity ?? 1}',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الكمية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: const InputDecoration(labelText: 'الكمية'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.primary(),
                    onPressed: () {
                      final newQuantity = int.tryParse(quantityController.text);
                      if (newQuantity != null && newQuantity > 0) {
                        final updatedItem = item.copyWith(
                          quantity: newQuantity,
                          totalPrice:
                              newQuantity.toDouble() * (item.unitPrice ?? 0.0),
                        );
                        context.read<EditInvoiceCubit>().updateItem(
                          index,
                          updatedItem,
                        );
                      }
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(quantityController.dispose);
  }
}
