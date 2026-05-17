import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
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

  const SupplierDebtLoaded({
    required this.debts,
    required this.filteredDebts,
  });

  @override
  List<Object?> get props => [debts, filteredDebts];

  SupplierDebtLoaded copyWith({
    List<SupplierDebtModel>? debts,
    List<SupplierDebtModel>? filteredDebts,
  }) {
    return SupplierDebtLoaded(
      debts: debts ?? this.debts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
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
  String _searchQuery = '';

  void _startRealtimeListener() {
    log('SupplierDebtCubit: Real-time stream disabled - using manual refresh for supplier names');
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
      emit(SupplierDebtLoaded(debts: _allDebts, filteredDebts: _filteredDebts));
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
          emit(SupplierPaymentSuccess('Ödeme kaydedildi: ${amount.toStringAsFixed(2)}'));
        }
        await getSupplierDebts();
      },
    );
  }

  void clearError() {
    if (isClosed) return;
    emit(SupplierDebtInitial());
  }

  double get totalDebt {
    return _filteredDebts.fold(0.0, (sum, debt) => sum + debt.remainingDebt);
  }

  double get totalInvoices {
    return _filteredDebts.fold(0.0, (sum, debt) => sum + debt.totalInvoices);
  }

  double get totalPaid {
    return _filteredDebts.fold(0.0, (sum, debt) => sum + debt.totalPaid);
  }

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