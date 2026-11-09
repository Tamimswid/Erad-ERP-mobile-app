import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../cities/data/models/city.dart';
import '../../../cities/data/repositories/city_repository.dart';
import '../../../cities/presentation/widgets/city_picker_field.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../data/models/invoice_list_filter.dart';

/// ورقة فلترة الفواتير: حالة الدفع، المدينة، والمنتجات.
class InvoiceFilterSheet extends StatefulWidget {
  final InvoiceListFilter initialFilter;
  final ProductRepository productRepository;
  final CityRepository cityRepository;

  const InvoiceFilterSheet({
    super.key,
    required this.initialFilter,
    required this.productRepository,
    required this.cityRepository,
  });

  static Future<InvoiceListFilter?> show(
    BuildContext context, {
    required InvoiceListFilter initialFilter,
  }) {
    return showModalBottomSheet<InvoiceListFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => InvoiceFilterSheet(
        initialFilter: initialFilter,
        productRepository: sl.sl<ProductRepository>(),
        cityRepository: sl.sl<CityRepository>(),
      ),
    );
  }

  @override
  State<InvoiceFilterSheet> createState() => _InvoiceFilterSheetState();
}

class _InvoiceFilterSheetState extends State<InvoiceFilterSheet> {
  static const int _productPageSize = 20;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  final TextEditingController _productSearchController =
      TextEditingController();
  final Map<String, InvoiceProductSelection> _selectedProducts = {};
  late String _paymentStatus;
  CityModel? _selectedCity;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<ProductModel> _productResults = const [];
  bool _isSearching = false;
  String? _productError;
  int _searchRequestId = 0;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    _paymentStatus = filter.paymentStatus;
    _dateFrom = filter.dateFrom;
    _dateTo = filter.dateTo;
    _selectedCity = filter.cityId == null
        ? null
        : CityModel(id: filter.cityId!, name: filter.cityName ?? '');
    for (final product in filter.products) {
      _selectedProducts[product.id] = product;
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _productSearchController.dispose();
    super.dispose();
  }

  void _onProductSearchChanged(String value) {
    _searchTimer?.cancel();
    setState(() {});
    _searchTimer = Timer(_searchDebounce, () => _searchProducts(value));
  }

  Future<void> _searchProducts(String query) async {
    final term = query.trim();
    if (term.isEmpty) {
      setState(() {
        _productResults = const [];
        _productError = null;
        _isSearching = false;
      });
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() {
      _isSearching = true;
      _productError = null;
    });

    final result = await widget.productRepository.getProductsPage(
      offset: 0,
      limit: _productPageSize,
      search: term,
    );
    if (!mounted || requestId != _searchRequestId) return;

    result.fold(
      (failure) => setState(() {
        _isSearching = false;
        _productError = failure.message;
        _productResults = const [];
      }),
      (page) => setState(() {
        _isSearching = false;
        _productResults = page.items;
      }),
    );
  }

  void _toggleProduct(ProductModel product) {
    setState(() {
      if (_selectedProducts.containsKey(product.id)) {
        _selectedProducts.remove(product.id);
      } else {
        _selectedProducts[product.id] = InvoiceProductSelection(
          id: product.id,
          name: product.name,
          measurement: product.measurement,
          unit: product.unit,
        );
      }
    });
  }

  void _removeProduct(InvoiceProductSelection product) {
    setState(() => _selectedProducts.remove(product.id));
  }

  void _selectYear(int year) {
    setState(() {
      _dateFrom = DateTime(year, 1, 1);
      _dateTo = DateTime(year, 12, 31);
    });
  }

  bool _isYearSelected(int year) {
    return _dateFrom?.year == year &&
        _dateFrom?.month == 1 &&
        _dateFrom?.day == 1 &&
        _dateTo?.year == year &&
        _dateTo?.month == 12 &&
        _dateTo?.day == 31;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = _dateFrom != null && _dateTo != null
        ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
        : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialRange,
      builder: (context, child) => child!,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _dateFrom = picked.start;
      _dateTo = picked.end;
    });
  }

  void _clearDateRange() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      InvoiceListFilter(
        paymentStatus: _paymentStatus,
        cityId: _selectedCity?.id,
        cityName: _selectedCity?.name,
        products: _selectedProducts.values.toList(growable: false),
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      ),
    );
  }

  void _clearAll() {
    Navigator.pop(context, const InvoiceListFilter());
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'فلترة الفواتير',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(sc.LucideIcons.x, size: 20),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  children: [
                    _buildSectionTitle('التاريخ'),
                    const SizedBox(height: 10),
                    _buildDateRangeSection(),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 16),
                    _buildSectionTitle('حالة الدفع'),
                    const SizedBox(height: 10),
                    _buildPaymentStatusOptions(),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 16),
                    _buildSectionTitle('المدينة'),
                    const SizedBox(height: 10),
                    CityPickerField(
                      value: _selectedCity,
                      onChanged: (city) => setState(() => _selectedCity = city),
                      repository: widget.cityRepository,
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 16),
                    _buildSectionTitle('المنتجات'),
                    const SizedBox(height: 4),
                    const Text(
                      'ابحث عن منتج ثم اختر منتجاً أو أكثر. تكفي مطابقة أي منتج.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_selectedProducts.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSelectedProducts(),
                    ],
                    const SizedBox(height: 12),
                    _buildProductSearchField(),
                    const SizedBox(height: 8),
                    _buildProductResults(),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: sc.Button(
                        alignment: Alignment.center,
                        style: sc.ButtonStyle.outline(),
                        onPressed: _clearAll,
                        child: const Text('مسح'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: sc.Button(
                        alignment: Alignment.center,
                        style: sc.ButtonStyle.primary(),
                        onPressed: _apply,
                        child: const Text('تطبيق'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDateRangeSection() {
    final years = List.generate(5, (index) => DateTime.now().year - index);
    final hasRange = _dateFrom != null || _dateTo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: years.map((year) {
            return _SelectionChip(
              label: '$year',
              selected: _isYearSelected(year),
              onTap: () => _selectYear(year),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateRangeField(
                label: 'من',
                date: _dateFrom,
                onTap: _pickDateRange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DateRangeField(
                label: 'إلى',
                date: _dateTo,
                onTap: _pickDateRange,
              ),
            ),
            if (hasRange) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: _clearDateRange,
                icon: const Icon(sc.LucideIcons.x, size: 18),
                color: AppColors.textSecondary,
                tooltip: 'مسح التاريخ',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentStatusOptions() {
    const options = [
      ('الكل', InvoiceListFilter.allPaymentStatus),
      ('دين', 'debt'),
      ('نقدي', 'cash'),
    ];

    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final (label, value) = option;
        return _SelectionChip(
          label: label,
          selected: _paymentStatus == value,
          onTap: () => setState(() => _paymentStatus = value),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedProducts() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedProducts.values.map((product) {
        return InputChip(
          label: Text(product.displayName),
          labelStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: AppColors.muted,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          deleteIconColor: AppColors.textSecondary,
          onDeleted: () => _removeProduct(product),
        );
      }).toList(),
    );
  }

  Widget _buildProductSearchField() {
    return TextField(
      controller: _productSearchController,
      onChanged: _onProductSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث عن منتج بالاسم...',
        hintStyle: const TextStyle(fontSize: 14),
        prefixIcon: const Icon(sc.LucideIcons.search, size: 20),
        suffixIcon: _productSearchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _productSearchController.clear();
                  _onProductSearchChanged('');
                },
                icon: const Icon(sc.LucideIcons.x, size: 16),
                color: AppColors.textSecondary,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildProductResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_productError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _productError!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _searchProducts(_productSearchController.text),
              child: const Text('حاول ثانية'),
            ),
          ],
        ),
      );
    }

    if (_productResults.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < _productResults.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider),
          _buildProductTile(_productResults[i]),
        ],
      ],
    );
  }

  Widget _buildProductTile(ProductModel product) {
    final isSelected = _selectedProducts.containsKey(product.id);
    final measurementLabel = [
      product.measurement,
      product.unit,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');

    return InkWell(
      onTap: () => _toggleProduct(product),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? AppColors.text
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (measurementLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      measurementLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(sc.LucideIcons.check, size: 18, color: AppColors.text),
          ],
        ),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateRangeField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            sc.LucideIcons.calendar,
            size: 18,
            color: date == null ? AppColors.textSecondary : AppColors.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          date == null ? 'اختر' : '${date!.day}/${date!.month}/${date!.year}',
          style: TextStyle(
            fontSize: 13,
            color: date == null ? AppColors.textSecondary : AppColors.text,
          ),
        ),
      ),
    );
  }
}
