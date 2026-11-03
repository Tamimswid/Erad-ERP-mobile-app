part of 'dashboard_cubit.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardFinancialsModel financials;
  final List<DashboardProductStockModel> productStock;
  final DashboardPeriod period;
  final String selectedYear;
  final DateTime selectedMonth;
  final DateTimeRange? customDateRange;

  const DashboardLoaded({
    required this.financials,
    this.productStock = const [],
    this.period = DashboardPeriod.year,
    required this.selectedYear,
    required this.selectedMonth,
    this.customDateRange,
  });

  bool get isCustomDateRange => period == DashboardPeriod.custom;

  double get totalProfit => financials.totalProfit;
  double get totalExpenses => financials.totalExpenses;
  double get netProfit => financials.netProfit;
  double get totalCustomerDebt => financials.totalCustomerDebt;
  double get totalSupplierDebt => financials.totalSupplierDebt;
  double get cashInHand => financials.cashInHand;
  double get totalWithdrawals => financials.totalWithdrawals;
  double get totalSalesRevenue => financials.totalSalesRevenue;
  double get totalPurchaseCost => financials.totalPurchaseCost;

  DashboardLoaded copyWith({
    DashboardFinancialsModel? financials,
    List<DashboardProductStockModel>? productStock,
    DashboardPeriod? period,
    String? selectedYear,
    DateTime? selectedMonth,
    DateTimeRange? customDateRange,
  }) {
    return DashboardLoaded(
      financials: financials ?? this.financials,
      productStock: productStock ?? this.productStock,
      period: period ?? this.period,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      customDateRange: customDateRange ?? this.customDateRange,
    );
  }

  @override
  List<Object?> get props => [
        financials,
        productStock,
        period,
        selectedYear,
        selectedMonth,
        customDateRange,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
