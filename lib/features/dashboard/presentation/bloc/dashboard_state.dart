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
  final String selectedYear;
  final DateTimeRange? customDateRange;
  final bool isCustomDateRange;

  const DashboardLoaded({
    required this.financials,
    this.productStock = const [],
    required this.selectedYear,
    this.customDateRange,
    this.isCustomDateRange = false,
  });

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
    String? selectedYear,
    DateTimeRange? customDateRange,
    bool? isCustomDateRange,
  }) {
    return DashboardLoaded(
      financials: financials ?? this.financials,
      productStock: productStock ?? this.productStock,
      selectedYear: selectedYear ?? this.selectedYear,
      customDateRange: customDateRange ?? this.customDateRange,
      isCustomDateRange: isCustomDateRange ?? this.isCustomDateRange,
    );
  }

  @override
  List<Object?> get props => [
        financials,
        productStock,
        selectedYear,
        customDateRange,
        isCustomDateRange,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
