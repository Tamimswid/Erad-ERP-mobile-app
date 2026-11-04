import 'dart:developer';

import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_totals_model.dart';
import 'package:erad/features/customer_debts/data/repositories/customer_debt_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'customer_debt_state.dart';

class CustomerDebtCubit extends Cubit<CustomerDebtState> {
  static const int pageSize = 10;

  final CustomerDebtRepository repository;
  final DataChangeNotifier _dataChanges;
  late int _dataChangeVersion;

  CustomerDebtCubit({
    required this.repository,
    required DataChangeNotifier dataChanges,
  }) : _dataChanges = dataChanges,
       super(CustomerDebtInitial()) {
    _dataChangeVersion = _dataChanges.versionOf(DataDomain.customerDebts);
    _dataChanges.addListener(_handleDataChange);
  }

  final List<CustomerDebtModel> _debts = [];
  CustomerDebtTotalsModel _totals = const CustomerDebtTotalsModel();
  int _offset = 0;
  int _requestId = 0;
  int _debtorCount = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  String _searchQuery = '';

  Future<void> getCustomerDebts() => loadFirstPage();

  void _handleDataChange() {
    if (isClosed) return;
    final version = _dataChanges.versionOf(DataDomain.customerDebts);
    if (version == _dataChangeVersion) return;
    _dataChangeVersion = version;
    loadFirstPage(showLoading: false);
  }

  Future<void> loadFirstPage({bool showLoading = true}) async {
    final requestId = ++_requestId;
    final previousOffset = _offset;
    final previousHasMore = _hasMore;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;

    if (showLoading && !isClosed) emit(CustomerDebtLoading());

    final result = await repository.getCustomerDebtsPage(
      offset: 0,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (failure) {
        _offset = previousOffset;
        _hasMore = previousHasMore;
        emit(CustomerDebtError(failure.message));
        if (_hasLoaded) _emitLoaded();
      },
      (page) {
        _debts
          ..clear()
          ..addAll(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;
        _hasLoaded = true;
        _emitLoaded();
      },
    );

    if (isClosed || requestId != _requestId) return;
    await _loadTotals();
    if (isClosed || requestId != _requestId) return;
    await _loadDebtorCount(requestId);
  }

  Future<void> loadMore() async {
    if (isClosed || !_hasMore || _isLoadingMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await repository.getCustomerDebtsPage(
      offset: _offset,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (_) {
        _isLoadingMore = false;
        _hasMore = false;
        _emitLoaded();
      },
      (page) {
        _debts.addAll(page.items);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(
      CustomerDebtLoaded(
        debts: List<CustomerDebtModel>.unmodifiable(_debts),
        filteredDebts: List<CustomerDebtModel>.unmodifiable(_debts),
        totals: _totals,
        debtorCount: _debtorCount,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }

  Future<void> _loadTotals() async {
    final result = await repository.getCustomerDebtTotals();
    if (isClosed) return;
    result.fold(
      (failure) {
        log('Failed to load customer totals: ${failure.message}');
      },
      (totals) {
        log('Customer totals loaded');
        _totals = totals;
        if (state is CustomerDebtLoaded) {
          emit((state as CustomerDebtLoaded).copyWith(totals: _totals));
        }
      },
    );
  }

  Future<void> _loadDebtorCount(int requestId) async {
    final result = await repository.getCustomerDebtCount(
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;
    result.fold((_) {}, (count) {
      _debtorCount = count;
      if (state is CustomerDebtLoaded) {
        emit((state as CustomerDebtLoaded).copyWith(debtorCount: count));
      }
    });
  }

  void searchCustomerDebts(String query) {
    final value = query.trim();
    if (value == _searchQuery) return;
    _searchQuery = value;
    loadFirstPage(showLoading: false);
  }

  Future<void> addPayment(
    String customerId,
    double amount,
    String? note,
    String paymentDate,
  ) async {
    if (isClosed) return;

    final wasLoaded = state is CustomerDebtLoaded;
    final snapshot = (
      debts: List<CustomerDebtModel>.of(_debts),
      totals: _totals,
    );

    final index = _debts.indexWhere((debt) => debt.id == customerId);
    if (index != -1 && amount > 0) {
      final debt = _debts[index];
      _debts[index] = debt.copyWith(totalPaid: debt.totalPaid + amount);
      _totals = CustomerDebtTotalsModel(
        totalDebtAll: (_totals.totalDebtAll - amount).clamp(0, double.infinity),
        totalPaidAll: _totals.totalPaidAll + amount,
        totalInvoicesAll: _totals.totalInvoicesAll,
      );
      if (wasLoaded) _emitLoaded();
    }

    final result = await repository.addPayment(
      customerId,
      amount,
      note,
      paymentDate,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        log('addPayment failed: ${failure.runtimeType} - ${failure.message}');
        _debts
          ..clear()
          ..addAll(snapshot.debts);
        _totals = snapshot.totals;
        emit(CustomerDebtError(failure.message));
        if (wasLoaded) _emitLoaded();
      },
      (_) {
        log('addPayment succeeded');
        if (isClosed) return;
        emit(PaymentSuccess('تم تسجيل الدفعة: ${amount.toStringAsFixed(2)}'));
        if (_hasLoaded) _emitLoaded();
        _dataChanges.notifyChanged(DataDomain.customerDebts);
      },
    );
  }

  void clearError() {
    if (isClosed) return;
    emit(CustomerDebtInitial());
  }

  double get totalDebt => _totals.totalDebtAll;

  double get totalInvoices => _totals.totalInvoicesAll;

  double get totalPaid => _totals.totalPaidAll;

  int get debtorCount => _debtorCount;

  List<CustomerDebtModel> get debtsWithDebt => _debts;

  bool get hasMore => _hasMore;

  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<void> close() {
    _dataChanges.removeListener(_handleDataChange);
    return super.close();
  }
}
