import 'package:equatable/equatable.dart';
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/withdrawal.dart';
import '../../data/models/partner.dart';
import '../../data/repositories/withdrawal_repository.dart';

part 'withdrawal_state.dart';

class WithdrawalCubit extends Cubit<WithdrawalState> {
  static const int pageSize = 10;

  final WithdrawalRepository withdrawalRepository;
  final DataChangeNotifier _dataChanges;
  int _dataChangeVersion = 0;

  final List<Withdrawal> _withdrawals = [];
  List<Partner> _partners = [];
  String? _selectedPartnerId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedYear;

  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;

  double _totalAmount = 0;
  int _totalCount = 0;
  double _averageAmount = 0;
  List<double> _monthlyData = List<double>.filled(12, 0);

  WithdrawalCubit({
    required this.withdrawalRepository,
    required DataChangeNotifier dataChanges,
  }) : _dataChanges = dataChanges,
       super(WithdrawalInitial()) {
    _dataChangeVersion = _dataChanges.versionOf(DataDomain.withdrawals);
    _dataChanges.addListener(_handleDataChange);
  }

  Future<void> refresh() => _reload(showLoading: false);

  void _handleDataChange() {
    if (isClosed) return;
    final version = _dataChanges.versionOf(DataDomain.withdrawals);
    if (version == _dataChangeVersion) return;
    _dataChangeVersion = version;
    refresh();
  }

  @override
  Future<void> close() {
    _dataChanges.removeListener(_handleDataChange);
    return super.close();
  }

  Future<void> loadInitial({required String year}) async {
    final yearInt = int.tryParse(year) ?? DateTime.now().year;
    _selectedYear = yearInt.toString();
    _startDate = DateTime(yearInt, 1, 1);
    _endDate = DateTime(yearInt, 12, 31);
    await _reload(showLoading: true, includePartners: true);
  }

  Future<void> loadMore() async {
    if (isClosed || !_hasMore || _isLoadingMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await withdrawalRepository.getWithdrawalsPage(
      offset: _offset,
      limit: pageSize,
      startDate: _startDate,
      endDate: _endDate,
      partnerId: _selectedPartnerId,
    );
    if (isClosed || requestId != _requestId) return;

    _isLoadingMore = false;
    result.fold(
      (_) {
        _hasMore = false;
        _emitLoaded();
      },
      (page) {
        _withdrawals.addAll(page.items);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _emitLoaded();
      },
    );
  }

  Future<void> _reload({
    bool showLoading = false,
    bool includePartners = false,
  }) async {
    final requestId = ++_requestId;
    final hadLoaded = _hasLoaded;
    final previousOffset = _offset;
    final previousHasMore = _hasMore;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;

    if (showLoading && !isClosed) emit(WithdrawalLoading());

    final pageFuture = withdrawalRepository.getWithdrawalsPage(
      offset: 0,
      limit: pageSize,
      startDate: _startDate,
      endDate: _endDate,
      partnerId: _selectedPartnerId,
    );
    final summaryFuture = withdrawalRepository.getWithdrawalsSummary(
      startDate: _startDate,
      endDate: _endDate,
      partnerId: _selectedPartnerId,
    );
    final partnersFuture = includePartners
        ? withdrawalRepository.getPartners()
        : null;

    final pageResult = await pageFuture;
    final summaryResult = await summaryFuture;
    final partnersResult = partnersFuture == null ? null : await partnersFuture;

    if (isClosed || requestId != _requestId) return;

    pageResult.fold(
      (failure) {
        _offset = previousOffset;
        _hasMore = previousHasMore;
        emit(WithdrawalError(failure.message));
        if (hadLoaded) _emitLoaded();
      },
      (page) {
        _withdrawals
          ..clear()
          ..addAll(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;

        summaryResult.fold(
          (_) {
            _totalAmount = 0;
            _totalCount = 0;
            _averageAmount = 0;
            _monthlyData = List<double>.filled(12, 0);
          },
          (summary) {
            _totalAmount = summary.totalAmount;
            _totalCount = summary.totalCount;
            _averageAmount = summary.averageAmount;
            _monthlyData = summary.monthlyData;
          },
        );

        if (partnersResult != null) {
          partnersResult.fold((_) {}, (partners) {
            _partners = partners;
          });
        }

        _hasLoaded = true;
        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(
      WithdrawalsLoaded(
        withdrawals: List<Withdrawal>.unmodifiable(_withdrawals),
        partners: _partners,
        totalAmount: _totalAmount,
        totalCount: _totalCount,
        averageAmount: _averageAmount,
        monthlyData: _monthlyData,
        selectedPartnerId: _selectedPartnerId,
        startDate: _startDate,
        endDate: _endDate,
        selectedYear: _selectedYear,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }

  Future<void> _reloadPartners() async {
    final result = await withdrawalRepository.getPartners();
    if (isClosed) return;
    result.fold((_) {}, (partners) {
      _partners = partners;
      _emitLoaded();
    });
  }

  Future<void> filterByPartner(String? partnerId) async {
    _selectedPartnerId = partnerId;
    await _reload();
  }

  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    _startDate = start;
    _endDate = end;
    _selectedYear = null;
    await _reload();
  }

  Future<void> filterByYear(String year) async {
    final yearInt = int.tryParse(year) ?? DateTime.now().year;
    _selectedYear = yearInt.toString();
    _startDate = DateTime(yearInt, 1, 1);
    _endDate = DateTime(yearInt, 12, 31);
    await _reload();
  }

  Future<void> clearFilters() async {
    _selectedPartnerId = null;
    _startDate = null;
    _endDate = null;
    _selectedYear = null;
    await _reload();
  }

  Future<void> createWithdrawal(Withdrawal withdrawal) async {
    if (isClosed) return;
    final snapshot = _snapshot();
    final optimistic = _withOptimisticId(withdrawal);
    if (_matchesFilters(optimistic)) {
      _withdrawals.insert(0, optimistic);
      _applyTotalsDelta(optimistic.amount, 1);
      _emitLoaded();
    }

    final result = await withdrawalRepository.createWithdrawal(withdrawal);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(WithdrawalError(failure.message));
        _emitLoaded();
      },
      (_) {
        emit(WithdrawalSuccess('تم إضافة السحب بنجاح'));
        if (_hasLoaded) _emitLoaded();
        _dataChanges.notifyChanged(DataDomain.withdrawals);
      },
    );
  }

  Future<void> updateWithdrawal(Withdrawal withdrawal) async {
    if (isClosed) return;
    final snapshot = _snapshot();
    final index = _withdrawals.indexWhere((item) => item.id == withdrawal.id);
    if (index != -1) {
      final previous = _withdrawals[index];
      final wasVisible = _matchesFilters(previous);
      final isVisible = _matchesFilters(withdrawal);
      if (isVisible) {
        _withdrawals[index] = withdrawal;
      } else {
        _withdrawals.removeAt(index);
      }
      if (wasVisible) _applyTotalsDelta(-previous.amount, -1);
      if (isVisible) _applyTotalsDelta(withdrawal.amount, 1);
      _emitLoaded();
    }

    final result = await withdrawalRepository.updateWithdrawal(withdrawal);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(WithdrawalError(failure.message));
        _emitLoaded();
      },
      (_) {
        emit(WithdrawalSuccess('تم تحديث السحب بنجاح'));
        if (_hasLoaded) _emitLoaded();
        _dataChanges.notifyChanged(DataDomain.withdrawals);
      },
    );
  }

  Future<void> deleteWithdrawal(String id) async {
    if (isClosed) return;
    final snapshot = _snapshot();
    final index = _withdrawals.indexWhere((item) => item.id == id);
    if (index != -1) {
      final removed = _withdrawals.removeAt(index);
      _applyTotalsDelta(-removed.amount, -1);
      if (_offset > 0) _offset--;
      _emitLoaded();
    }

    final result = await withdrawalRepository.deleteWithdrawal(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(WithdrawalError(failure.message));
        _emitLoaded();
      },
      (_) {
        emit(WithdrawalSuccess('تم حذف السحب بنجاح'));
        if (_hasLoaded) _emitLoaded();
        _dataChanges.notifyChanged(DataDomain.withdrawals);
      },
    );
  }

  ({
    List<Withdrawal> withdrawals,
    double totalAmount,
    int totalCount,
    double averageAmount,
    List<double> monthlyData,
    int offset,
    bool hasMore,
  })
  _snapshot() => (
    withdrawals: List<Withdrawal>.from(_withdrawals),
    totalAmount: _totalAmount,
    totalCount: _totalCount,
    averageAmount: _averageAmount,
    monthlyData: List<double>.from(_monthlyData),
    offset: _offset,
    hasMore: _hasMore,
  );

  void _restore(
    ({
      List<Withdrawal> withdrawals,
      double totalAmount,
      int totalCount,
      double averageAmount,
      List<double> monthlyData,
      int offset,
      bool hasMore,
    })
    snapshot,
  ) {
    _withdrawals
      ..clear()
      ..addAll(snapshot.withdrawals);
    _totalAmount = snapshot.totalAmount;
    _totalCount = snapshot.totalCount;
    _averageAmount = snapshot.averageAmount;
    _monthlyData = snapshot.monthlyData;
    _offset = snapshot.offset;
    _hasMore = snapshot.hasMore;
  }

  Withdrawal _withOptimisticId(Withdrawal withdrawal) {
    if (withdrawal.id.isNotEmpty) return withdrawal;
    return withdrawal.copyWith(
      id: 'optimistic_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  bool _matchesFilters(Withdrawal withdrawal) {
    if (_selectedPartnerId != null &&
        withdrawal.partnerId != _selectedPartnerId) {
      return false;
    }
    final date = DateTime(
      withdrawal.withdrawalDate.year,
      withdrawal.withdrawalDate.month,
      withdrawal.withdrawalDate.day,
    );
    if (_startDate != null) {
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      if (date.isBefore(start)) return false;
    }
    if (_endDate != null) {
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
      if (date.isAfter(end)) return false;
    }
    return true;
  }

  void _applyTotalsDelta(double amountDelta, int countDelta) {
    _totalAmount += amountDelta;
    if (_totalAmount < 0) _totalAmount = 0;
    _totalCount += countDelta;
    if (_totalCount < 0) _totalCount = 0;
    _averageAmount = _totalCount == 0 ? 0 : _totalAmount / _totalCount;
  }

  Future<void> createPartner(Partner partner) async {
    if (isClosed) return;
    final result = await withdrawalRepository.createPartner(partner);
    if (isClosed) return;
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (_) => _reloadPartners(),
    );
  }

  Future<void> deletePartner(String id) async {
    if (isClosed) return;
    final result = await withdrawalRepository.deletePartner(id);
    if (isClosed) return;
    result.fold((failure) => emit(WithdrawalError(failure.message)), (_) {
      if (_selectedPartnerId == id) {
        _selectedPartnerId = null;
        _reload();
      } else {
        _reloadPartners();
      }
    });
  }

  void clearError() {
    if (isClosed) return;
    if (state is WithdrawalError) {
      _emitLoaded();
    }
  }
}
