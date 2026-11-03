import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/dashboard_financials.dart';
import '../../data/models/dashboard_period.dart';
import '../../data/models/dashboard_product_stock.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/helpers/dashboard_filter_helper.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardPeriod _period = DashboardPeriod.year;
  String _selectedYear = DateTime.now().year.toString();
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _customDateRange;

  DashboardCubit({
    required DashboardRepository dashboardRepository,
  })  : _dashboardRepository = dashboardRepository,
        super(const DashboardInitial()) {
    refreshData();
  }

  Future<void> loadDashboardData({
    required DashboardPeriod period,
    String? year,
    DateTime? month,
    DateTimeRange? customDateRange,
  }) async {
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

    emit(const DashboardLoading());

    try {
      final results = await Future.wait([
        _dashboardRepository.getFinancials(
          startDate: startDate,
          endDate: endDate,
        ),
        _dashboardRepository.getProductStock(),
      ]);

      DashboardFinancialsModel financials =
          const DashboardFinancialsModel(userId: '');
      final financialsResult =
          results[0] as Either<Failure, DashboardFinancialsModel>;
      financialsResult.fold((failure) => null, (data) => financials = data);

      List<DashboardProductStockModel> productStock = [];
      final stockResult =
          results[1] as Either<Failure, List<DashboardProductStockModel>>;
      stockResult.fold((failure) => null, (data) => productStock = data);

      emit(DashboardLoaded(
        financials: financials,
        productStock: productStock,
        period: period,
        selectedYear: nextYear,
        selectedMonth: nextMonth,
        customDateRange:
            period == DashboardPeriod.custom ? nextRange : null,
      ));
    } catch (e) {
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
    loadDashboardData(
      period: _period,
      customDateRange: _customDateRange,
    );
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
}
