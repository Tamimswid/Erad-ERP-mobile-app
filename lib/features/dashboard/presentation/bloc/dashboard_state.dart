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
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double totalWithdrawals;
  final double totalProfit;
  final double netProfit;
  final int totalCustomers;
  final int totalProducts;
  final List<Map<String, dynamic>> monthlyChartData;
  final List<Map<String, dynamic>> recentInvoices;
  final List<Map<String, dynamic>> topProductsBySales;
  final List<Map<String, dynamic>>? topProductsByPurchases;
  final List<Map<String, dynamic>> remainingStock;
  final String selectedYear;
  final DateTimeRange? customDateRange;
  final bool isCustomDateRange;

  const DashboardLoaded({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.totalWithdrawals,
    required this.totalProfit,
    required this.netProfit,
    required this.totalCustomers,
    required this.totalProducts,
    required this.monthlyChartData,
    required this.recentInvoices,
    required this.topProductsBySales,
    this.topProductsByPurchases,
    this.remainingStock = const [],
    required this.selectedYear,
    this.customDateRange,
    this.isCustomDateRange = false,
  });

  DashboardLoaded copyWith({
    double? totalSales,
    double? totalPurchases,
    double? totalExpenses,
    double? totalWithdrawals,
    double? totalProfit,
    double? netProfit,
    int? totalCustomers,
    int? totalProducts,
    List<Map<String, dynamic>>? monthlyChartData,
    List<Map<String, dynamic>>? recentInvoices,
    List<Map<String, dynamic>>? topProductsBySales,
    List<Map<String, dynamic>>? topProductsByPurchases = const [],
    List<Map<String, dynamic>>? remainingStock,
    String? selectedYear,
    DateTimeRange? customDateRange,
    bool? isCustomDateRange,
  }) {
    return DashboardLoaded(
      totalSales: totalSales ?? this.totalSales,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      totalProfit: totalProfit ?? this.totalProfit,
      netProfit: netProfit ?? this.netProfit,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalProducts: totalProducts ?? this.totalProducts,
      monthlyChartData: monthlyChartData ?? this.monthlyChartData,
      recentInvoices: recentInvoices ?? this.recentInvoices,
      topProductsBySales: topProductsBySales ?? this.topProductsBySales,
      topProductsByPurchases: topProductsByPurchases ?? this.topProductsByPurchases,
      remainingStock: remainingStock ?? this.remainingStock,
      selectedYear: selectedYear ?? this.selectedYear,
      customDateRange: customDateRange ?? this.customDateRange,
      isCustomDateRange: isCustomDateRange ?? this.isCustomDateRange,
    );
  }

  @override
  List<Object?> get props => [
        totalSales,
        totalPurchases,
        totalExpenses,
        totalWithdrawals,
        totalProfit,
        netProfit,
        totalCustomers,
        totalProducts,
        monthlyChartData,
        recentInvoices,
        topProductsBySales,
        topProductsByPurchases,
        remainingStock,
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
