import 'dart:developer';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/services/pdf_invoice_service.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/core/widgets/app_pagination_list.dart';
import 'package:erad/core/widgets/date_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockTrackingPage extends StatefulWidget {
  const StockTrackingPage({super.key});

  @override
  State<StockTrackingPage> createState() => _StockTrackingPageState();
}

class _StockTrackingPageState extends State<StockTrackingPage> {
  static const int _pageSize = 10;

  final _supabase = Supabase.instance.client;
  final Map<String, List<String>> _categoryProductIdsCache = {};

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  Set<String> _selectedProductIds = {};
  String? _selectedCategoryId;
  bool _isLoading = true;
  bool _isLoadingProducts = false;
  bool _isGeneratingPdf = false;

  int _offset = 0;
  int _productsRequestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  DateTimeRange? _customDateRange;
  bool _isCustomDateRange = false;
  String? _selectedYear;
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _loadCategories();
      await _loadProducts(reset: true);
    } catch (e) {
      log('Failed to load stock data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    final userId = await UserService.getUserId();
    if (userId == null) return;

    final response = await _supabase
        .from('categories')
        .select('id, name')
        .eq('user_id', userId)
        .order('name');

    if (!mounted) return;
    setState(() {
      _categories = List<Map<String, dynamic>>.from(response);
      _availableYears = [DateTime.now().year.toString()];
    });
  }

  Future<List<String>> _categoryProductIds(String categoryId) async {
    final cached = _categoryProductIdsCache[categoryId];
    if (cached != null) return cached;

    final userId = await UserService.getUserId();
    if (userId == null) return [];

    final response = await _supabase
        .from('products')
        .select('id')
        .eq('user_id', userId)
        .eq('category_id', categoryId);

    final ids = response.map((row) => row['id'] as String).toList();
    _categoryProductIdsCache[categoryId] = ids;
    return ids;
  }

  Future<void> _loadProducts({bool reset = false}) async {
    final int requestId;
    if (reset) {
      requestId = ++_productsRequestId;
      _offset = 0;
      _hasMore = true;
      _isLoadingMore = false;
      _products = [];
      if (mounted) setState(() => _isLoadingProducts = true);
    } else {
      if (!_hasMore || _isLoadingMore || _isLoadingProducts) return;
      requestId = _productsRequestId;
      if (mounted) setState(() => _isLoadingMore = true);
    }

    try {
      final userId = await UserService.getUserId();
      if (userId == null) return;

      var query = _supabase
          .from('dashboard_product_stock')
          .select()
          .eq('user_id', userId);

      if (_selectedCategoryId != null) {
        final productIds = await _categoryProductIds(_selectedCategoryId!);
        if (!mounted || requestId != _productsRequestId) return;
        if (productIds.isEmpty) {
          setState(() {
            _products = [];
            _hasMore = false;
            _isLoadingMore = false;
            _isLoadingProducts = false;
          });
          return;
        }
        query = query.inFilter('product_id', productIds);
      }

      final response = await query
          .order('product_display_name', ascending: true)
          .order('product_id', ascending: true)
          .range(_offset, _offset + _pageSize);

      final rows = List<Map<String, dynamic>>.from(response);
      final hasMore = rows.length > _pageSize;
      final pageItems = hasMore ? rows.sublist(0, _pageSize) : rows;

      if (!mounted || requestId != _productsRequestId) return;
      setState(() {
        _products = [..._products, ...pageItems];
        _offset += pageItems.length;
        _hasMore = hasMore;
        _isLoadingMore = false;
        _isLoadingProducts = false;
      });
    } catch (e) {
      log('Failed to load stock data: $e');
      if (mounted && requestId == _productsRequestId) {
        setState(() {
          _isLoadingMore = false;
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _loadProducts(reset: true);
  }

  void _toggleProduct(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _selectAllFiltered() {
    setState(() {
      _selectedProductIds = _products
          .map((p) => p['product_id'] as String)
          .toSet();
    });
  }

  void _deselectAll() {
    setState(() => _selectedProductIds.clear());
  }

  String _dateRangeLabel() {
    if (_isCustomDateRange && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end;
      return 'من ${start.day}/${start.month}/${start.year} إلى ${end.day}/${end.month}/${end.year}';
    }
    if (_selectedYear != null) {
      return 'السنة: $_selectedYear';
    }
    return '';
  }

  Future<void> _generatePdf() async {
    if (_selectedProductIds.isEmpty) return;
    setState(() => _isGeneratingPdf = true);
    try {
      String companyName = '';
      final userId = await UserService.getUserId();
      if (userId != null) {
        final profile = await _supabase
            .from('profiles')
            .select('business_name')
            .eq('id', userId)
            .maybeSingle();
        if (profile != null) {
          companyName = (profile['business_name'] as String?) ?? '';
        }
      }

      var selectedProducts = <Map<String, dynamic>>[];
      if (userId != null) {
        final response = await _supabase
            .from('dashboard_product_stock')
            .select()
            .eq('user_id', userId)
            .inFilter('product_id', _selectedProductIds.toList())
            .order('product_display_name', ascending: true);
        selectedProducts = List<Map<String, dynamic>>.from(response);
      }

      final pdfService = PdfInvoiceService();
      final pdf = await pdfService.generateStockPdf(
        companyName: companyName,
        dateRangeLabel: _dateRangeLabel(),
        products: selectedProducts,
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'stock_tracking.pdf',
      );
    } catch (e) {
      log('Stock PDF generation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل إنشاء PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _showDateFilter() async {
    final now = DateTime.now();
    final years = _availableYears.isEmpty
        ? [now.year.toString()]
        : _availableYears;

    await DateFilterSheet.show(
      context: context,
      selectedYear: _selectedYear,
      availableYears: years,
      customDateRange: _customDateRange,
      isCustomDateRange: _isCustomDateRange,
      onYearSelected: (year) {
        setState(() {
          _selectedYear = year;
          _isCustomDateRange = false;
          _customDateRange = null;
        });
      },
      onDateRangeSelected: (range) {
        setState(() {
          _customDateRange = range;
          _isCustomDateRange = true;
          _selectedYear = null;
        });
      },
      onClearFilter: () {
        setState(() {
          _selectedYear = null;
          _customDateRange = null;
          _isCustomDateRange = false;
        });
      },
      onDateRangePickerTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _customDateRange,
          locale: const Locale('ar'),
        );
        if (picked != null && mounted) {
          Navigator.pop(context);
          setState(() {
            _customDateRange = picked;
            _isCustomDateRange = true;
            _selectedYear = null;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter =
        _selectedYear != null ||
        (_isCustomDateRange && _customDateRange != null);

    return sc.Scaffold(
      headers: [
        sc.AppBar(
          title: const Text('تتبع المخزون'),
          leading: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(sc.LucideIcons.arrowRight, size: 22),
            ),
          ],
          trailing: [
            if (_isGeneratingPdf)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              if (_selectedProductIds.isNotEmpty)
                IconButton(
                  icon: const Icon(sc.LucideIcons.fileDown),
                  onPressed: _generatePdf,
                ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(sc.LucideIcons.calendar),
                    onPressed: _showDateFilter,
                  ),
                  if (hasFilter)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoriesSection(),
                _buildSelectionActions(),
                Expanded(child: _buildProductsList()),
              ],
            ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(null, 'الكل'),
          const SizedBox(width: 8),
          ..._categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildCategoryChip(cat['id'], cat['name'] ?? ''),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? categoryId, String label) {
    final isSelected = _selectedCategoryId == categoryId;
    return GestureDetector(
      onTap: () => _selectCategory(categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : AppColors.text,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          sc.Button(
            style: sc.ButtonStyle.ghost(),
            onPressed: _selectAllFiltered,
            leading: const Icon(sc.LucideIcons.circleCheck, size: 16),
            child: const Text('تحديد الكل'),
          ),
          const SizedBox(width: 8),
          sc.Button(
            style: sc.ButtonStyle.ghost(),
            onPressed: _deselectAll,
            leading: const Icon(sc.LucideIcons.circleX, size: 16),
            child: const Text('إلغاء الكل'),
          ),
          const Spacer(),
          Text(
            '${_selectedProductIds.length} مختار',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoadingProducts && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sc.LucideIcons.packageSearch,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد منتجات',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        AppPaginationSliverList(
          itemCount: _products.length,
          hasMore: _hasMore,
          isLoadingMore: _isLoadingMore,
          onLoadMore: () => _loadProducts(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separator: const SizedBox(height: 6),
          bottomSpace: 24,
          itemBuilder: (context, index) {
            final product = _products[index];
            final productId = product['product_id'] as String;
            final name = product['product_display_name'] as String? ?? '';
            final purchased = product['total_purchased_qty'] ?? 0;
            final isSelected = _selectedProductIds.contains(productId);

            return sc.Card(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => _toggleProduct(productId),
                  title: Text(name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    'المشتريات: $purchased',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  dense: true,
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
