import 'dart:developer';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/services/pdf_invoice_service.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/core/widgets/date_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockTrackingPage extends StatefulWidget {
  const StockTrackingPage({super.key});

  @override
  State<StockTrackingPage> createState() => _StockTrackingPageState();
}

class _StockTrackingPageState extends State<StockTrackingPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allProducts = [];
  Set<String> _selectedProductIds = {};
  String? _selectedCategoryId;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  DateTimeRange? _customDateRange;
  bool _isCustomDateRange = false;
  String? _selectedYear;
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategoryId == null) return _allProducts;
    return _allProducts
        .where((p) => p['category_id'] == _selectedCategoryId)
        .toList();
  }

  Future<void> _loadData() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return;

      final results = await Future.wait([
        _supabase.from('categories').select('id, name').eq('user_id', userId).order('name'),
        _supabase.from('dashboard_product_stock').select().eq('user_id', userId),
        _supabase.from('products').select('id, category_id').eq('user_id', userId),
      ]);

      final categories = List<Map<String, dynamic>>.from(results[0]);
      final stockData = List<Map<String, dynamic>>.from(results[1]);
      final productsData = List<Map<String, dynamic>>.from(results[2]);

      final categoryMap = {for (var p in productsData) p['id']: p['category_id']};

      final products = stockData.map((item) {
        final productId = item['product_id'];
        return {
          ...item,
          'category_id': categoryMap[productId],
        };
      }).toList();

      final years = products
          .map((_) => DateTime.now().year.toString())
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      if (mounted) {
        setState(() {
          _categories = categories;
          _allProducts = products;
          _availableYears = years;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Failed to load stock data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
      _selectedProductIds = _filteredProducts.map((p) => p['product_id'] as String).toSet();
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

      final selectedProducts = _allProducts
          .where((p) => _selectedProductIds.contains(p['product_id']))
          .toList();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _showDateFilter() async {
    final now = DateTime.now();
    final years = _availableYears.isEmpty ? [now.year.toString()] : _availableYears;

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
    final hasFilter = _selectedYear != null ||
        (_isCustomDateRange && _customDateRange != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تتبع المخزون'),
        centerTitle: true,
        actions: [
          if (_isGeneratingPdf)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (_selectedProductIds.isNotEmpty)
              IconButton(
                icon: const Icon(Iconsax.document_download),
                onPressed: _generatePdf,
              ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.calendar),
                  onPressed: _showDateFilter,
                ),
                if (hasFilter)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 8, height: 8,
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
      body: _isLoading
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
          ..._categories.map((cat) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildCategoryChip(cat['id'], cat['name'] ?? ''),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? categoryId, String label) {
    final isSelected = _selectedCategoryId == categoryId;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.text,
            fontSize: 13,
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
          TextButton.icon(
            onPressed: _selectAllFiltered,
            icon: const Icon(Iconsax.tick_circle, size: 16),
            label: const Text('تحديد الكل'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _deselectAll,
            icon: const Icon(Iconsax.close_circle, size: 16),
            label: const Text('إلغاء الكل'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            '${_selectedProductIds.length} مختار',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box_search, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'لا توجد منتجات',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final productId = product['product_id'] as String;
        final name = product['product_display_name'] as String? ?? '';
        final purchased = product['total_purchased_qty'] ?? 0;
        final isSelected = _selectedProductIds.contains(productId);

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (_) => _toggleProduct(productId),
            title: Text(name, style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              'المشتريات: $purchased',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            dense: true,
            activeColor: AppColors.primary,
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        );
      },
    );
  }
}
