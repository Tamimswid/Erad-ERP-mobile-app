import 'dart:developer';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/services/pdf_invoice_service.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/core/widgets/date_filter_sheet.dart';
import 'package:erad/core/widgets/invoice_card_widget.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerInvoiceDetailPage extends StatefulWidget {
  final String partyId;
  final String partyName;
  final bool isSupplier;

  const CustomerInvoiceDetailPage({
    super.key,
    required this.partyId,
    required this.partyName,
    this.isSupplier = false,
  });

  @override
  State<CustomerInvoiceDetailPage> createState() =>
      _CustomerInvoiceDetailPageState();
}

class _CustomerInvoiceDetailPageState
    extends State<CustomerInvoiceDetailPage> {
  final _supabase = Supabase.instance.client;

  List<dynamic> _invoices = [];
  List<dynamic> _filteredInvoices = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  DateTimeRange? _customDateRange;
  bool _isCustomDateRange = false;
  String? _selectedYear;
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  DateTime _getInvoiceDate(dynamic inv) {
    if (inv is SalesInvoice) return inv.invoiceDate;
    if (inv is PurchaseInvoice) return inv.invoiceDate;
    return DateTime.now();
  }

  Future<void> _loadInvoices() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return;

      final String table =
          widget.isSupplier ? 'purchase_invoices' : 'sales_invoices';
      final String idField =
          widget.isSupplier ? 'supplier_id' : 'customer_id';

      final response = await _supabase
          .from(table)
          .select()
          .eq('user_id', userId)
          .eq(idField, widget.partyId)
          .isFilter('deleted_at', null)
          .order('invoice_date', ascending: false);

      if (mounted) {
        final List<dynamic> invoices;

        if (widget.isSupplier) {
          invoices = (response as List).map((json) {
            final map = Map<String, dynamic>.from(json);
            map['supplier_name'] = widget.partyName;
            return PurchaseInvoice.fromJson(map);
          }).toList();
        } else {
          invoices = (response as List).map((json) {
            final map = Map<String, dynamic>.from(json);
            map['customer_name'] = widget.partyName;
            return SalesInvoice.fromJson(map);
          }).toList();
        }

        final years = invoices
            .map((inv) => _getInvoiceDate(inv).year.toString())
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

        setState(() {
          _invoices = invoices;
          _filteredInvoices = invoices;
          _availableYears = years;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Failed to load invoices: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    List<dynamic> filtered = List.from(_invoices);

    if (_isCustomDateRange && _customDateRange != null) {
      filtered = filtered.where((inv) {
        final date = _getInvoiceDate(inv);
        return !date.isBefore(_customDateRange!.start) &&
            !date.isAfter(_customDateRange!.end);
      }).toList();
    } else if (_selectedYear != null) {
      filtered = filtered
          .where(
              (inv) => _getInvoiceDate(inv).year.toString() == _selectedYear)
          .toList();
    }

    setState(() => _filteredInvoices = filtered);
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
        _applyFilter();
      },
      onDateRangeSelected: (range) {
        setState(() {
          _customDateRange = range;
          _isCustomDateRange = true;
          _selectedYear = null;
        });
        _applyFilter();
      },
      onClearFilter: () {
        setState(() {
          _selectedYear = null;
          _customDateRange = null;
          _isCustomDateRange = false;
        });
        _applyFilter();
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
          _applyFilter();
        }
      },
    );
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
    if (_filteredInvoices.isEmpty) return;
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

      final pdfService = PdfInvoiceService();
      final pdf = await pdfService.generateInvoiceListPdf(
        companyName: companyName,
        partyName: widget.partyName,
        dateRangeLabel: _dateRangeLabel(),
        invoices: _filteredInvoices,
        type: widget.isSupplier ? 'purchase' : 'sale',
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'invoices_${widget.partyId}.pdf',
      );
    } catch (e) {
      log('PDF generation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = _selectedYear != null ||
        (_isCustomDateRange && _customDateRange != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.partyName),
        centerTitle: true,
        actions: [
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
            IconButton(
              icon: const Icon(Iconsax.document_download),
              onPressed: _filteredInvoices.isEmpty ? null : _generatePdf,
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.calendar),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredInvoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.receipt_disscount,
                          size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد فواتير',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _filteredInvoices[index];
                    return InvoiceCardWidget(
                      invoice: invoice,
                      type: widget.isSupplier ? 'purchase' : 'sale',
                      onTap: () {},
                    );
                  },
                ),
    );
  }
}
