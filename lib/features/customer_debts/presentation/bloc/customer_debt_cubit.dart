import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/repositories/customer_debt_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'customer_debt_state.dart';

class CustomerDebtCubit extends Cubit<CustomerDebtState> {
  final CustomerDebtRepository repository;
  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _paymentsSubscription;

  CustomerDebtCubit({required this.repository}) : super(CustomerDebtInitial()) {
    _startRealtimeListener();
  }

  List<CustomerDebtModel> _allDebts = [];
  List<CustomerDebtModel> _filteredDebts = [];
  String _searchQuery = '';

  void _startRealtimeListener() {
    _paymentsSubscription = _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final filtered = data
              .where((p) => p['payment_type'] == 'customer' && p['customer_id'] != null)
              .toList();
          return List<Map<String, dynamic>>.from(filtered);
        })
        .listen((_) {
          log('CustomerDebtCubit: Payment change detected - refreshing data');
          getCustomerDebts();
        });
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
      emit(CustomerDebtLoaded(debts: _allDebts, filteredDebts: _filteredDebts));
    }
  }

  Future<void> getCustomerDebts() async {
    if (isClosed) return;
    final result = await repository.getCustomerDebts();
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerDebtError(failure.message)),
      (debts) {
        _allDebts = debts;
        _applySearchFilter();
      },
    );
  }

  Future<void> searchCustomerDebts(String query) async {
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
    if (state is CustomerDebtLoaded) {
      final currentState = state as CustomerDebtLoaded;
      emit(currentState.copyWith(filteredDebts: _filteredDebts));
    } else {
      emit(CustomerDebtLoaded(debts: _allDebts, filteredDebts: _filteredDebts));
    }
  }

  Future<void> addPayment(String customerId, double amount, String? note, String paymentDate) async {
    if (isClosed) return;
    emit(PaymentProcessing());

    final result = await repository.addPayment(customerId, amount, note, paymentDate);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerDebtError(failure.message)),
      (_) async {
        if (!isClosed) {
          emit(PaymentSuccess('تم تسجيل الدفعة: ${amount.toStringAsFixed(2)}'));
        }
        await getCustomerDebts();
      },
    );
  }

  void clearError() {
    if (isClosed) return;
    emit(CustomerDebtInitial());
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

  List<CustomerDebtModel> get debtsWithDebt {
    return _filteredDebts;
  }

  @override
  Future<void> close() {
    _paymentsSubscription?.cancel();
    return super.close();
  }
}
