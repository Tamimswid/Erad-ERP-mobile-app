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
  final int totalCustomers;
  final int totalProducts;
  final List<Map<String, dynamic>> recentInvoices;
  final String selectedYear;
  final DateTimeRange? customDateRange;
  final bool isCustomDateRange;

  const DashboardLoaded({
    required this.financials,
    this.productStock = const [],
    this.totalCustomers = 0,
    this.totalProducts = 0,
    this.recentInvoices = const [],
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

  DashboardLoaded copyWith({
    DashboardFinancialsModel? financials,
    List<DashboardProductStockModel>? productStock,
    int? totalCustomers,
    int? totalProducts,
    List<Map<String, dynamic>>? recentInvoices,
    String? selectedYear,
    DateTimeRange? customDateRange,
    bool? isCustomDateRange,
  }) {
    return DashboardLoaded(
      financials: financials ?? this.financials,
      productStock: productStock ?? this.productStock,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalProducts: totalProducts ?? this.totalProducts,
      recentInvoices: recentInvoices ?? this.recentInvoices,
      selectedYear: selectedYear ?? this.selectedYear,
      customDateRange: customDateRange ?? this.customDateRange,
      isCustomDateRange: isCustomDateRange ?? this.isCustomDateRange,
    );
  }

  @override
  List<Object?> get props => [
        financials,
        productStock,
        totalCustomers,
        totalProducts,
        recentInvoices,
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
