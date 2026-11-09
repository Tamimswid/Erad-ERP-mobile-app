import 'package:dartz/dartz.dart';
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/dashboard_daily_summary.dart';
import '../../data/models/dashboard_financials.dart';
import '../../data/models/dashboard_period.dart';
import '../../data/models/dashboard_product_stock.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/helpers/dashboard_filter_helper.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  static const List<DataDomain> _watchedDomains = [
    DataDomain.invoices,
    DataDomain.customerDebts,
    DataDomain.supplierDebts,
    DataDomain.products,
    DataDomain.expenses,
    DataDomain.withdrawals,
  ];

  final DashboardRepository _dashboardRepository;
  final DataChangeNotifier _dataChanges;
  final Map<DataDomain, int> _dataChangeVersions = {};

  DashboardPeriod _period = DashboardPeriod.year;
  String _selectedYear = DateTime.now().year.toString();
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _customDateRange;
  int _requestId = 0;
  bool _refreshScheduled = false;

  DashboardCubit({
    required DashboardRepository dashboardRepository,
    required DataChangeNotifier dataChanges,
  }) : _dashboardRepository = dashboardRepository,
       _dataChanges = dataChanges,
       super(const DashboardInitial()) {
    for (final domain in _watchedDomains) {
      _dataChangeVersions[domain] = _dataChanges.versionOf(domain);
    }
    _dataChanges.addListener(_handleDataChange);
    refreshData();
  }

  void _handleDataChange() {
    if (isClosed) return;

    var changed = false;
    for (final domain in _watchedDomains) {
      final version = _dataChanges.versionOf(domain);
      if (version != _dataChangeVersions[domain]) {
        _dataChangeVersions[domain] = version;
        changed = true;
      }
    }
    if (!changed || _refreshScheduled) return;

    _refreshScheduled = true;
    Future.microtask(() {
      _refreshScheduled = false;
      if (isClosed) return;
      loadDashboardData(
        period: _period,
        customDateRange: _customDateRange,
        showLoading: false,
      );
    });
  }

  Future<void> loadDashboardData({
    required DashboardPeriod period,
    String? year,
    DateTime? month,
    DateTimeRange? customDateRange,
    bool showLoading = true,
  }) async {
    final requestId = ++_requestId;
    final nextYear = year ?? _selectedYear;
    final nextMonth = month ?? _selectedMonth;
    final nextRange = customDateRange ?? _customDateRange;

    _period = period;
    _selectedYear = nextYear;
    _selectedMonth = nextMonth;
    if (period == DashboardPeriod.custom) {
      _customDateRange = nextRange;
    }

    final dateRange = DashboardFilterHelper.getRangeForPeriod(
      period: period,
      year: nextYear,
      month: nextMonth,
      customDateRange: nextRange,
    );

    final startDate = DashboardFilterHelper.formatDateForApi(dateRange.start);
    final endDate = DashboardFilterHelper.formatDateForApi(dateRange.end);

    if (showLoading && !isClosed) emit(const DashboardLoading());

    final previous = state is DashboardLoaded ? state as DashboardLoaded : null;

    try {
      final results = await Future.wait([
        _dashboardRepository.getFinancials(
          startDate: startDate,
          endDate: endDate,
        ),
        _dashboardRepository.getProductStock(),
        _dashboardRepository.getDailySummary(
          startDate: startDate,
          endDate: endDate,
        ),
      ]);
      if (isClosed || requestId != _requestId) return;

      final financialsResult =
          results[0] as Either<Failure, DashboardFinancialsModel>;
      final stockResult =
          results[1] as Either<Failure, List<DashboardProductStockModel>>;
      final dailySummaryResult =
          results[2] as Either<Failure, List<DashboardDailySummaryModel>>;

      DashboardFinancialsModel? financials;
      Failure? financialsFailure;
      financialsResult.fold(
        (failure) => financialsFailure = failure,
        (data) => financials = data,
      );

      List<DashboardProductStockModel>? productStock;
      Failure? stockFailure;
      stockResult.fold(
        (failure) => stockFailure = failure,
        (data) => productStock = data,
      );

      List<DashboardDailySummaryModel>? dailySummary;
      dailySummaryResult.fold((_) {}, (data) => dailySummary = data);

      final isSamePeriod =
          previous != null &&
          previous.period == period &&
          previous.selectedYear == nextYear &&
          previous.selectedMonth == nextMonth &&
          previous.customDateRange == nextRange;

      if (financials == null && productStock == null && previous == null) {
        emit(
          DashboardError(
            financialsFailure?.message ??
                stockFailure?.message ??
                'Failed to load dashboard data',
          ),
        );
        return;
      }

      emit(
        DashboardLoaded(
          financials:
              financials ??
              previous?.financials ??
              const DashboardFinancialsModel(userId: ''),
          productStock:
              productStock ??
              previous?.productStock ??
              const <DashboardProductStockModel>[],
          dailySummary:
              dailySummary ??
              (isSamePeriod
                  ? previous.dailySummary
                  : const <DashboardDailySummaryModel>[]),
          period: period,
          selectedYear: nextYear,
          selectedMonth: nextMonth,
          customDateRange: period == DashboardPeriod.custom ? nextRange : null,
        ),
      );
    } catch (e) {
      if (isClosed || requestId != _requestId) return;
      if (!showLoading && state is DashboardLoaded) return;
      emit(DashboardError('Failed to load dashboard data: $e'));
    }
  }

  void setPeriod(DashboardPeriod period) {
    if (period == DashboardPeriod.custom) return;
    loadDashboardData(period: period);
  }

  void setCustomDateRange(DateTimeRange dateRange) {
    loadDashboardData(
      period: DashboardPeriod.custom,
      customDateRange: dateRange,
    );
  }

  void setYear(String year) {
    loadDashboardData(period: DashboardPeriod.year, year: year);
  }

  void clearCustomDateRange() {
    loadDashboardData(period: DashboardPeriod.year);
  }

  void refreshData() {
    loadDashboardData(period: _period, customDateRange: _customDateRange);
  }

  void retry() => refreshData();

  List<String> getAvailableYears() => DashboardFilterHelper.getAvailableYears();

  String getDateRangeLabel() {
    if (state is! DashboardLoaded) return '';
    final loaded = state as DashboardLoaded;
    return DashboardFilterHelper.getDateRangeLabel(
      selectedYear: loaded.selectedYear,
      customDateRange: loaded.customDateRange,
    );
  }

  @override
  Future<void> close() {
    _dataChanges.removeListener(_handleDataChange);
    return super.close();
  }
}
