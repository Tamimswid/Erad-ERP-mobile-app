import 'dart:developer';

import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_totals_model.dart';
import 'package:erad/features/customer_debts/data/repositories/customer_debt_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'customer_debt_state.dart';

class CustomerDebtCubit extends Cubit<CustomerDebtState> {
  static const int pageSize = 10;

  final CustomerDebtRepository repository;

  CustomerDebtCubit({required this.repository}) : super(CustomerDebtInitial());

  final List<CustomerDebtModel> _debts = [];
  CustomerDebtTotalsModel _totals = const CustomerDebtTotalsModel();
  int _offset = 0;
  int _requestId = 0;
  int _debtorCount = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  Future<void> getCustomerDebts() => loadFirstPage();

  Future<void> loadFirstPage({bool showLoading = true}) async {
    final requestId = ++_requestId;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _debts.clear();

    if (showLoading && !isClosed) emit(CustomerDebtLoading());

    final result = await repository.getCustomerDebtsPage(
      offset: 0,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold((failure) => emit(CustomerDebtError(failure.message)), (page) {
      _debts.addAll(page.items);
      _offset = page.items.length;
      _hasMore = page.hasMore;
      _emitLoaded();
    });

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
    emit(PaymentProcessing());

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
        emit(CustomerDebtError(failure.message));
      },
      (_) {
        log('addPayment succeeded');
        if (!isClosed) {
          emit(PaymentSuccess('تم تسجيل الدفعة: ${amount.toStringAsFixed(2)}'));
        }
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
}
