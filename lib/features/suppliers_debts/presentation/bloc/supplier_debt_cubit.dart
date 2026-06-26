import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
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

  const SupplierDebtLoaded({
    required this.debts,
    required this.filteredDebts,
    this.totals = const SupplierDebtTotalsModel(),
  });

  @override
  List<Object?> get props => [debts, filteredDebts, totals];

  SupplierDebtLoaded copyWith({
    List<SupplierDebtModel>? debts,
    List<SupplierDebtModel>? filteredDebts,
    SupplierDebtTotalsModel? totals,
  }) {
    return SupplierDebtLoaded(
      debts: debts ?? this.debts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
      totals: totals ?? this.totals,
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
  final SupplierDebtRepository repository;
  StreamSubscription<Either<Failure, List<SupplierDebtModel>>>? _debtsSubscription;

  SupplierDebtCubit({required this.repository}) : super(SupplierDebtInitial()) {
    _startRealtimeListener();
  }

  List<SupplierDebtModel> _allDebts = [];
  List<SupplierDebtModel> _filteredDebts = [];
  SupplierDebtTotalsModel _totals = const SupplierDebtTotalsModel();
  String _searchQuery = '';

  void _startRealtimeListener() {
    log('SupplierDebtCubit: Starting real-time listener...');
    _debtsSubscription = repository.watchSupplierDebts().listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) {
            log('SupplierDebtCubit: Stream error - ${failure.message}');
            emit(SupplierDebtError(failure.message));
          },
          (debts) {
            log('SupplierDebtCubit: Received ${debts.length} suppliers with debt');
            _allDebts = debts;
            _applySearchFilter();
          },
        );
      },
      onError: (error) {
        log('SupplierDebtCubit: Stream error - $error');
        if (!isClosed) {
          emit(SupplierDebtError('Stream error: $error'));
        }
      },
    );
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredDebts = _allDebts;
    } else {
      _filteredDebts = _allDebts.where((debt) {
        return debt.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (debt.phone?.contains(_searchQuery) ?? false);
      }).toList();
    }

    if (!isClosed) {
      emit(SupplierDebtLoaded(
        debts: _allDebts,
        filteredDebts: _filteredDebts,
        totals: _totals,
      ));
    }
  }

  Future<void> getSupplierDebts() async {
    if (isClosed) return;
    emit(SupplierDebtLoading());
    final result = await repository.getSupplierDebts();
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierDebtError(failure.message)),
      (debts) {
        _allDebts = debts;
        _applySearchFilter();
      },
    );
    await _loadTotals();
  }

  Future<void> _loadTotals() async {
    final result = await repository.getSupplierDebtTotals();
    if (isClosed) return;
    result.fold(
      (failure) {
        log('Failed to load supplier totals: ${failure.message}');
        _totals = SupplierDebtTotalsModel(
          totalDebtAll:
              _filteredDebts.fold(0.0, (sum, d) => sum + d.remainingDebt),
          totalInvoicesAll:
              _filteredDebts.fold(0.0, (sum, d) => sum + d.totalInvoices),
          totalPaidAll:
              _filteredDebts.fold(0.0, (sum, d) => sum + d.totalPaid),
        );
      },
      (totals) {
        log('Supplier totals loaded');
        _totals = totals;
      },
    );
    if (state is SupplierDebtLoaded) {
      emit((state as SupplierDebtLoaded).copyWith(totals: _totals));
    }
  }

  Future<void> searchSupplierDebts(String query) async {
    _searchQuery = query.trim();
    
    if (_searchQuery.isEmpty) {
      _filteredDebts = _allDebts;
    } else {
      _filteredDebts = _allDebts.where((debt) {
        return debt.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (debt.phone?.contains(_searchQuery) ?? false);
      }).toList();
    }

    if (isClosed) return;
    if (state is SupplierDebtLoaded) {
      final currentState = state as SupplierDebtLoaded;
      emit(currentState.copyWith(filteredDebts: _filteredDebts));
    } else {
      emit(SupplierDebtLoaded(debts: _allDebts, filteredDebts: _filteredDebts));
    }
  }

  Future<void> addPayment(String supplierId, double amount, String? note, String paymentDate) async {
    if (isClosed) return;
    emit(SupplierPaymentProcessing());

    final result = await repository.addPayment(supplierId, amount, note, paymentDate);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierDebtError(failure.message)),
      (_) async {
        if (!isClosed) {
          emit(SupplierPaymentSuccess('تم تسجيل الدفعة: ${amount.toStringAsFixed(2)}'));
        }
        await getSupplierDebts();
      },
    );
  }

  void clearError() {
    if (isClosed) return;
    emit(SupplierDebtInitial());
  }

  double get totalDebt => _totals.totalDebtAll;

  double get totalInvoices => _totals.totalInvoicesAll;

  double get totalPaid => _totals.totalPaidAll;

  int get debtorCount {
    return _filteredDebts.length;
  }

  List<SupplierDebtModel> get debtsWithDebt {
    return _filteredDebts;
  }

  @override
  Future<void> close() {
    _debtsSubscription?.cancel();
    return super.close();
  }
}