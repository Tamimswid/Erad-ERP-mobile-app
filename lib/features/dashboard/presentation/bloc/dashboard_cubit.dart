import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/dashboard_financials.dart';
import '../../data/models/dashboard_product_stock.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/helpers/dashboard_filter_helper.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardCubit({
    required DashboardRepository dashboardRepository,
  })  : _dashboardRepository = dashboardRepository,
        super(const DashboardInitial()) {
    _initialize();
  }

  void _initialize() {
    final currentYear = DateTime.now().year.toString();
    loadDashboardData(year: currentYear);
  }

  /// Dashboard verilerini yükler.
  Future<void> loadDashboardData({
    required String year,
    DateTimeRange? customDateRange,
  }) async {
    emit(const DashboardLoading());

    try {
      final dateRange = DashboardFilterHelper.getActiveDateRange(
        selectedYear: year,
        customDateRange: customDateRange,
      );

      final startDate = DashboardFilterHelper.formatDateForApi(dateRange.start);
      final endDate = DashboardFilterHelper.formatDateForApi(dateRange.end);

      // Paralel olarak gerekli verileri çek
      final results = await Future.wait([
        _dashboardRepository.getFinancials(startDate: startDate, endDate: endDate),
        _dashboardRepository.getProductStock(),
      ]);

      // Finansal veriler
      DashboardFinancialsModel financials = const DashboardFinancialsModel(userId: '');
      final financialsResult = results[0] as Either<Failure, DashboardFinancialsModel>;
      financialsResult.fold(
        (failure) => null,
        (data) => financials = data,
      );

      // Ürün stokları
      List<DashboardProductStockModel> productStock = [];
      final stockResult = results[1] as Either<Failure, List<DashboardProductStockModel>>;
      stockResult.fold(
        (failure) => null,
        (data) => productStock = data,
      );

      emit(DashboardLoaded(
        financials: financials,
        productStock: productStock,
        selectedYear: year,
        customDateRange: customDateRange,
        isCustomDateRange: customDateRange != null,
      ));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard data: $e'));
    }
  }

  void setYear(String year) {
    loadDashboardData(year: year);
  }

  void setCustomDateRange(DateTimeRange dateRange) {
    loadDashboardData(
      year: DateTime.now().year.toString(),
      customDateRange: dateRange,
    );
  }

  void clearCustomDateRange() {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      loadDashboardData(year: currentState.selectedYear);
    }
  }

  void refreshData() {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      loadDashboardData(
        year: currentState.selectedYear,
        customDateRange: currentState.customDateRange,
      );
    }
  }

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
