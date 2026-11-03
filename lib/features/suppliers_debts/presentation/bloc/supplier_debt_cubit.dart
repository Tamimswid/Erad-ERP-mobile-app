import 'dart:developer';

import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_totals_model.dart';
import 'package:erad/features/suppliers_debts/data/repositories/supplier_debt_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SupplierDebtState extends Equatable {
  const SupplierDebtState();

  @override
  List<Object?> get props => [];
}

class SupplierDebtInitial extends SupplierDebtState {}

class SupplierDebtLoading extends SupplierDebtState {}

class SupplierDebtLoaded extends SupplierDebtState {
  final List<SupplierDebtModel> debts;
  final List<SupplierDebtModel> filteredDebts;
  final SupplierDebtTotalsModel totals;
  final int debtorCount;
  final bool hasMore;
  final bool isLoadingMore;

  const SupplierDebtLoaded({
    required this.debts,
    required this.filteredDebts,
    this.totals = const SupplierDebtTotalsModel(),
    this.debtorCount = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
    debts,
    filteredDebts,
    totals,
    debtorCount,
    hasMore,
    isLoadingMore,
  ];

  SupplierDebtLoaded copyWith({
    List<SupplierDebtModel>? debts,
    List<SupplierDebtModel>? filteredDebts,
    SupplierDebtTotalsModel? totals,
    int? debtorCount,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SupplierDebtLoaded(
      debts: debts ?? this.debts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
      totals: totals ?? this.totals,
      debtorCount: debtorCount ?? this.debtorCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SupplierDebtError extends SupplierDebtState {
  final String message;

  const SupplierDebtError(this.message);

  @override
  List<Object?> get props => [message];
}

class SupplierDebtSuccess extends SupplierDebtState {
  final String message;

  const SupplierDebtSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SupplierPaymentProcessing extends SupplierDebtState {}

class SupplierPaymentSuccess extends SupplierDebtState {
  final String message;

  const SupplierPaymentSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SupplierDebtCubit extends Cubit<SupplierDebtState> {
  static const int pageSize = 10;

  final SupplierDebtRepository repository;

  SupplierDebtCubit({required this.repository}) : super(SupplierDebtInitial());

  final List<SupplierDebtModel> _debts = [];
  SupplierDebtTotalsModel _totals = const SupplierDebtTotalsModel();
  int _offset = 0;
  int _requestId = 0;
  int _debtorCount = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  Future<void> getSupplierDebts() => loadFirstPage();

  Future<void> loadFirstPage({bool showLoading = true}) async {
    final requestId = ++_requestId;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _debts.clear();

    if (showLoading && !isClosed) emit(SupplierDebtLoading());

    final result = await repository.getSupplierDebtsPage(
      offset: 0,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold((failure) => emit(SupplierDebtError(failure.message)), (page) {
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

    final result = await repository.getSupplierDebtsPage(
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
      SupplierDebtLoaded(
        debts: List<SupplierDebtModel>.unmodifiable(_debts),
        filteredDebts: List<SupplierDebtModel>.unmodifiable(_debts),
        totals: _totals,
        debtorCount: _debtorCount,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }

  Future<void> _loadTotals() async {
    final result = await repository.getSupplierDebtTotals();
    if (isClosed) return;
    result.fold(
      (failure) {
        log('Failed to load supplier totals: ${failure.message}');
      },
      (totals) {
        log('Supplier totals loaded');
        _totals = totals;
        if (state is SupplierDebtLoaded) {
          emit((state as SupplierDebtLoaded).copyWith(totals: _totals));
        }
      },
    );
  }

  Future<void> _loadDebtorCount(int requestId) async {
    final result = await repository.getSupplierDebtCount(
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;
    result.fold((_) {}, (count) {
      _debtorCount = count;
      if (state is SupplierDebtLoaded) {
        emit((state as SupplierDebtLoaded).copyWith(debtorCount: count));
      }
    });
  }

  void searchSupplierDebts(String query) {
    final value = query.trim();
    if (value == _searchQuery) return;
    _searchQuery = value;
    loadFirstPage(showLoading: false);
  }

  Future<void> addPayment(
    String supplierId,
    double amount,
    String? note,
    String paymentDate,
  ) async {
    if (isClosed) return;
    emit(SupplierPaymentProcessing());

    final result = await repository.addPayment(
      supplierId,
      amount,
      note,
      paymentDate,
    );
    if (isClosed) return;
    result.fold((failure) => emit(SupplierDebtError(failure.message)), (_) {
      if (!isClosed) {
        emit(
          SupplierPaymentSuccess(
            'تم تسجيل الدفعة: ${amount.toStringAsFixed(2)}',
          ),
        );
      }
    });
  }

  void clearError() {
    if (isClosed) return;
    emit(SupplierDebtInitial());
  }

  double get totalDebt => _totals.totalDebtAll;

  double get totalInvoices => _totals.totalInvoicesAll;

  double get totalPaid => _totals.totalPaidAll;

  int get debtorCount => _debtorCount;

  List<SupplierDebtModel> get debtsWithDebt => _debts;

  bool get hasMore => _hasMore;

  bool get isLoadingMore => _isLoadingMore;
}
