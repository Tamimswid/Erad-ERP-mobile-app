import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/utils/paged_result.dart';
import '../../data/repositories/report_repository.dart';
import '../../../invoices/data/models/sales_invoice.dart';
import '../../../invoices/data/models/purchase_invoice.dart';

part 'party_invoice_state.dart';

class PartyInvoiceCubit extends Cubit<PartyInvoiceState> {
  static const int pageSize = 10;

  final ReportRepository _repository;

  String _partyId = '';
  bool _isSupplier = false;

  final List<dynamic> _invoices = [];
  List<String> _availableYears = [];

  String? _selectedYear;
  DateTimeRange? _customDateRange;
  bool _isCustomDateRange = false;

  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  PartyInvoiceCubit(this._repository) : super(const PartyInvoiceInitial());

  String? get selectedYear => _selectedYear;
  DateTimeRange? get customDateRange => _customDateRange;
  bool get isCustomDateRange => _isCustomDateRange;

  List<String> get availableYears => _availableYears.isEmpty
      ? [DateTime.now().year.toString()]
      : _availableYears;

  Future<void> loadInvoices(String partyId, bool isSupplier) async {
    _partyId = partyId;
    _isSupplier = isSupplier;
    _selectedYear = null;
    _customDateRange = null;
    _isCustomDateRange = false;
    _loadYears();
    await loadFirstPage();
  }

  Future<void> loadFirstPage({bool showLoading = true}) async {
    if (_partyId.isEmpty || isClosed) return;

    final requestId = ++_requestId;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _invoices.clear();

    if (showLoading && !isClosed) emit(const PartyInvoiceLoading());

    final result = await _fetchPage(0);
    if (isClosed || requestId != _requestId) return;

    result.fold((failure) => emit(PartyInvoiceError(failure.message)), (page) {
      _invoices.addAll(page.items);
      _offset = page.items.length;
      _hasMore = page.hasMore;
      _emitLoaded();
    });
  }

  Future<void> loadMore() async {
    if (_partyId.isEmpty || isClosed || !_hasMore || _isLoadingMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await _fetchPage(_offset);
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (_) {
        _isLoadingMore = false;
        _hasMore = false;
        _emitLoaded();
      },
      (page) {
        _invoices.addAll(page.items);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
        _emitLoaded();
      },
    );
  }

  Future<void> setYear(String year) async {
    _selectedYear = year;
    _isCustomDateRange = false;
    _customDateRange = null;
    await loadFirstPage(showLoading: false);
  }

  Future<void> setCustomDateRange(DateTimeRange range) async {
    _customDateRange = range;
    _isCustomDateRange = true;
    _selectedYear = null;
    await loadFirstPage(showLoading: false);
  }

  Future<void> clearFilter() async {
    _selectedYear = null;
    _customDateRange = null;
    _isCustomDateRange = false;
    await loadFirstPage(showLoading: false);
  }

  Future<Either<Failure, List<dynamic>>> getInvoicesForPdf() async {
    if (_partyId.isEmpty) return const Right(<dynamic>[]);

    if (_isSupplier) {
      final result = await _repository.getPurchaseInvoicesBySupplier(_partyId);
      return result.map((invoices) => invoices.where(_matchesFilter).toList());
    }

    final result = await _repository.getSalesInvoicesByCustomer(_partyId);
    return result.map((invoices) => invoices.where(_matchesFilter).toList());
  }

  Future<Either<Failure, PagedResult<dynamic>>> _fetchPage(int offset) async {
    if (_isSupplier) {
      final result = await _repository.getPurchaseInvoicesPage(
        supplierId: _partyId,
        offset: offset,
        limit: pageSize,
        year: _selectedYear,
        startDate: _isCustomDateRange ? _customDateRange?.start : null,
        endDate: _isCustomDateRange ? _customDateRange?.end : null,
      );
      return result.map(
        (page) =>
            PagedResult<dynamic>(items: page.items, hasMore: page.hasMore),
      );
    }

    final result = await _repository.getSalesInvoicesPage(
      customerId: _partyId,
      offset: offset,
      limit: pageSize,
      year: _selectedYear,
      startDate: _isCustomDateRange ? _customDateRange?.start : null,
      endDate: _isCustomDateRange ? _customDateRange?.end : null,
    );
    return result.map(
      (page) => PagedResult<dynamic>(items: page.items, hasMore: page.hasMore),
    );
  }

  Future<void> _loadYears() async {
    final result = _isSupplier
        ? await _repository.getPurchaseInvoiceYears(_partyId)
        : await _repository.getSalesInvoiceYears(_partyId);
    if (isClosed) return;
    result.fold((_) {}, (years) => _availableYears = years);
  }

  bool _matchesFilter(dynamic invoice) {
    final date = _invoiceDate(invoice);
    if (_isCustomDateRange && _customDateRange != null) {
      return !date.isBefore(_customDateRange!.start) &&
          !date.isAfter(_customDateRange!.end);
    }
    if (_selectedYear != null) {
      return date.year.toString() == _selectedYear;
    }
    return true;
  }

  DateTime _invoiceDate(dynamic invoice) {
    if (invoice is SalesInvoice) return invoice.invoiceDate;
    if (invoice is PurchaseInvoice) return invoice.invoiceDate;
    return DateTime.now();
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(
      PartyInvoiceLoaded(
        invoices: List<dynamic>.unmodifiable(_invoices),
        totalCount: _invoices.length,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }
}
