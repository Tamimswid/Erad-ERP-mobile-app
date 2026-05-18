import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/withdrawal.dart';
import '../../data/models/partner.dart';
import '../../data/repositories/withdrawal_repository.dart';

part 'withdrawal_state.dart';

class WithdrawalCubit extends Cubit<WithdrawalState> {
  final WithdrawalRepository withdrawalRepository;
  StreamSubscription<Either<Failure, List<Withdrawal>>>? _withdrawalsSubscription;
  StreamSubscription<Either<Failure, List<Partner>>>? _partnersSubscription;

  WithdrawalCubit({required this.withdrawalRepository})
      : super(WithdrawalInitial()) {
    emit(WithdrawalLoading());
    // Use delayed to ensure loading state is visible for at least a moment
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) {
        _startRealtimeListeners();
      }
    });
  }

  List<Withdrawal> _allWithdrawals = [];
  List<Partner> _allPartners = [];
  String? _selectedPartnerId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedYear;

  void _startRealtimeListeners() {
    emit(WithdrawalLoading());
    // Listen to withdrawals stream
    _withdrawalsSubscription = withdrawalRepository
        .watchWithdrawals()
        .listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) => emit(WithdrawalError(failure.message)),
          (withdrawals) {
            _allWithdrawals = withdrawals;
            _applyFilters();
          },
        );
      },
    );

    // Listen to partners stream
    _partnersSubscription = withdrawalRepository.watchPartners().listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) => emit(WithdrawalError(failure.message)),
          (partners) {
            _allPartners = partners;
            _applyFilters();
          },
        );
      },
    );
  }

  void _applyFilters() {
    if (isClosed) return;

    var filteredWithdrawals = _allWithdrawals;

    if (_selectedPartnerId != null) {
      filteredWithdrawals = filteredWithdrawals
          .where((w) => w.partnerId == _selectedPartnerId)
          .toList();
    }

    if (_selectedYear != null) {
      final year = int.parse(_selectedYear!);
      filteredWithdrawals = filteredWithdrawals
          .where((w) => w.withdrawalDate.year == year)
          .toList();
    }

    if (_startDate != null) {
      filteredWithdrawals = filteredWithdrawals
          .where((w) => w.withdrawalDate.isAfter(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      filteredWithdrawals = filteredWithdrawals
          .where((w) => w.withdrawalDate.isBefore(_endDate!))
          .toList();
    }

    // Sort by date descending (newest first)
    filteredWithdrawals.sort((a, b) => b.withdrawalDate.compareTo(a.withdrawalDate));

    _emitLoadedState(filteredWithdrawals);
  }

  Future<void> loadData({DateTime? startDate, DateTime? endDate, String? partnerId}) async {
    if (isClosed) return;

    _startDate = startDate;
    _endDate = endDate;
    _selectedPartnerId = partnerId;

    // Re-apply filters with new parameters
    _applyFilters();
  }

  void _emitLoadedState(List<Withdrawal> filteredWithdrawals) {
    if (isClosed) return;
    final monthlyData = _calculateMonthlyData(filteredWithdrawals);
    final totalAmount = filteredWithdrawals.fold<double>(0, (sum, w) => sum + w.amount);
    final totalCount = filteredWithdrawals.length;
    final averageAmount = totalCount > 0 ? (totalAmount / totalCount).toDouble() : 0.0;

    emit(WithdrawalsLoaded(
      withdrawals: filteredWithdrawals,
      partners: _allPartners,
      totalAmount: totalAmount,
      totalCount: totalCount,
      averageAmount: averageAmount,
      monthlyData: monthlyData,
      selectedPartnerId: _selectedPartnerId,
      startDate: _startDate,
      endDate: _endDate,
      selectedYear: _selectedYear,
    ));
  }

  List<double> _calculateMonthlyData(List<Withdrawal> withdrawals) {
    final data = List<double>.filled(12, 0);
    for (final w in withdrawals) {
      final month = w.withdrawalDate.month - 1;
      data[month] += w.amount;
    }
    return data;
  }

  void filterByPartner(String? partnerId) {
    _selectedPartnerId = partnerId;
    _applyFilters();
  }

  void filterByDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _selectedYear = null;
    _applyFilters();
  }

  void filterByYear(String year) {
    _selectedYear = year;
    _startDate = null;
    _endDate = null;
    _applyFilters();
  }

  void clearFilters() {
    _selectedPartnerId = null;
    _startDate = null;
    _endDate = null;
    _selectedYear = null;
    _applyFilters();
  }

  Future<void> createWithdrawal(Withdrawal withdrawal) async {
    if (isClosed) return;
    final result = await withdrawalRepository.createWithdrawal(withdrawal);
    if (isClosed) return;
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (createdWithdrawal) {
        emit(WithdrawalSuccess('تم إضافة السحب بنجاح'));
        // Immediately emit loaded state so UI doesn't break
        _applyFilters();
      },
    );
  }

  Future<void> updateWithdrawal(Withdrawal withdrawal) async {
    if (isClosed) return;
    final result = await withdrawalRepository.updateWithdrawal(withdrawal);
    if (isClosed) return;
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (updatedWithdrawal) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> deleteWithdrawal(String id) async {
    if (isClosed) return;
    final result = await withdrawalRepository.deleteWithdrawal(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (_) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> createPartner(Partner partner) async {
    if (isClosed) return;
    final result = await withdrawalRepository.createPartner(partner);
    if (isClosed) return;
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (createdPartner) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> deletePartner(String id) async {
    if (isClosed) return;
    final result = await withdrawalRepository.deletePartner(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (_) {
        // Real-time stream will automatically update the UI
        if (_selectedPartnerId == id) {
          _selectedPartnerId = null;
        }
      },
    );
  }

  void clearError() {
    if (isClosed) return;
    if (state is WithdrawalError) {
      _emitLoadedState(_allWithdrawals);
    }
  }

  @override
  Future<void> close() {
    _withdrawalsSubscription?.cancel();
    _partnersSubscription?.cancel();
    return super.close();
  }

  @Deprecated('Use loadData instead')
  Future<void> getWithdrawals({DateTime? startDate, DateTime? endDate}) async {
    await loadData(startDate: startDate, endDate: endDate);
  }
}
