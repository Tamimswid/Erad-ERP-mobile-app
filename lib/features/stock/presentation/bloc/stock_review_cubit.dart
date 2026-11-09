import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/data_change_notifier.dart';
import '../../data/models/stock_category.dart';
import '../../data/models/stock_review_item.dart';
import '../../data/repositories/stock_repository.dart';

part 'stock_review_state.dart';

class StockReviewCubit extends Cubit<StockReviewState> {
  static const int pageSize = 10;
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const int lowStockWarningThreshold = 5;

  final StockRepository _repository;
  final DataChangeNotifier _dataChanges;

  final List<StockReviewItem> _items = [];
  final List<StockCategory> _categories = [];

  String _searchQuery = '';
  String? _selectedCategoryId;
  DateTimeRange? _dateRange;
  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  Timer? _searchTimer;
  int _productVersion = 0;
  int _invoiceVersion = 0;

  StockReviewCubit({
    required StockRepository stockRepository,
    required DataChangeNotifier dataChanges,
  }) : _repository = stockRepository,
       _dataChanges = dataChanges,
       super(const StockReviewInitial()) {
    _productVersion = _dataChanges.versionOf(DataDomain.products);
    _invoiceVersion = _dataChanges.versionOf(DataDomain.invoices);
    _dataChanges.addListener(_handleDataChange);
  }

  String? get selectedCategoryId => _selectedCategoryId;

  DateTimeRange? get dateRange => _dateRange;

  List<StockCategory> get categories => List.unmodifiable(_categories);

  Future<void> loadInitial() async {
    if (!isClosed) emit(const StockReviewLoading());
    await _loadCategories();
    if (isClosed) return;
    await _loadFirstPage(showLoading: false);
  }

  /// 300ms debounce: ardışık yazışlarda sadece son sorgu sunucuya gider.
  void updateSearch(String query) {
    final term = query.trim();
    _searchTimer?.cancel();
    if (term == _searchQuery) return;
    _searchTimer = Timer(searchDebounce, () {
      _searchQuery = term;
      _loadFirstPage(showLoading: false);
    });
  }

  Future<void> selectCategory(String? categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    await _loadFirstPage(showLoading: false);
  }

  Future<void> setDateRange(DateTimeRange? range) async {
    _dateRange = range;
    await _loadFirstPage(showLoading: false);
  }

  Future<void> reload() => _loadFirstPage();

  Future<void> loadMore() async {
    if (isClosed || !_hasMore || _isLoadingMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await _repository.getStockPage(
      offset: _offset,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedCategoryId,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (failure) {
        _isLoadingMore = false;
        _hasMore = false;
        emit(StockReviewError(failure.message));
        _emitLoaded();
      },
      (page) {
        _items.addAll(page.items);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
        _emitLoaded();
      },
    );
  }

  Future<void> _loadFirstPage({bool showLoading = true}) async {
    final requestId = ++_requestId;
    final previousOffset = _offset;
    final previousHasMore = _hasMore;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    if (showLoading && !isClosed) emit(const StockReviewLoading());

    final result = await _repository.getStockPage(
      offset: 0,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedCategoryId,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (failure) {
        _offset = previousOffset;
        _hasMore = previousHasMore;
        emit(StockReviewError(failure.message));
        if (_hasLoaded) _emitLoaded();
      },
      (page) {
        _items
          ..clear()
          ..addAll(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;
        _hasLoaded = true;
        _emitLoaded();
      },
    );
  }

  Future<void> _loadCategories() async {
    final result = await _repository.getCategories();
    if (isClosed) return;
    result.fold((_) {}, (categories) {
      _categories
        ..clear()
        ..addAll(categories);
    });
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(
      StockReviewLoaded(
        List<StockReviewItem>.unmodifiable(_items),
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }

  Future<void> _handleDataChange() async {
    if (isClosed) return;
    final productVersion = _dataChanges.versionOf(DataDomain.products);
    final invoiceVersion = _dataChanges.versionOf(DataDomain.invoices);
    if (productVersion == _productVersion &&
        invoiceVersion == _invoiceVersion) {
      return;
    }

    final productsChanged = productVersion != _productVersion;
    _productVersion = productVersion;
    _invoiceVersion = invoiceVersion;

    if (productsChanged) await _loadCategories();
    if (isClosed || !_hasLoaded) return;
    await _loadFirstPage(showLoading: false);
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    _dataChanges.removeListener(_handleDataChange);
    return super.close();
  }
}
