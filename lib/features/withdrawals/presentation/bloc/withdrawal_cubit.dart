import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/withdrawal.dart';
import '../../data/models/partner.dart';
import '../../data/repositories/withdrawal_repository.dart';

part 'withdrawal_state.dart';

class WithdrawalCubit extends Cubit<WithdrawalState> {
  static const int pageSize = 10;

  final WithdrawalRepository withdrawalRepository;

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

  double _totalAmount = 0;
  int _totalCount = 0;
  double _averageAmount = 0;
  List<double> _monthlyData = List<double>.filled(12, 0);

  WithdrawalCubit({required this.withdrawalRepository})
      : super(WithdrawalInitial());

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
    final partnersFuture =
        includePartners ? withdrawalRepository.getPartners() : null;

    final pageResult = await pageFuture;
    final summaryResult = await summaryFuture;
    final partnersResult = partnersFuture == null ? null : await partnersFuture;

    if (isClosed || requestId != _requestId) return;

    pageResult.fold(
      (failure) => emit(WithdrawalError(failure.message)),
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

        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(WithdrawalsLoaded(
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
    ));
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
    final result = await withdrawalRepository.createWithdrawal(withdrawal);
    if (isClosed) return;
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(WithdrawalSuccess('تم إضافة السحب بنجاح'));
        _reload();
      },
    );
  }

  Future<void> updateWithdrawal(Withdrawal withdrawal) async {
    if (isClosed) return;
    final result = await withdrawalRepository.updateWithdrawal(withdrawal);
    if (isClosed) return;
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(WithdrawalSuccess('تم تحديث السحب بنجاح'));
        _reload();
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
        if (isClosed) return;
        emit(WithdrawalSuccess('تم حذف السحب بنجاح'));
        _reload();
      },
    );
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
    result.fold(
      (failure) => emit(WithdrawalError(failure.message)),
      (_) {
        if (_selectedPartnerId == id) {
          _selectedPartnerId = null;
          _reload();
        } else {
          _reloadPartners();
        }
      },
    );
  }

  void clearError() {
    if (isClosed) return;
    if (state is WithdrawalError) {
      _emitLoaded();
    }
  }
}
