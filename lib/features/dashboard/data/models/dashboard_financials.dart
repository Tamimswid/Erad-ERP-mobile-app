import 'package:equatable/equatable.dart';

class DashboardFinancialsModel extends Equatable {
  final String userId;
  final double totalProfit;
  final double totalExpenses;
  final double netProfit;
  final double totalCustomerDebt;
  final double totalSupplierDebt;
  final double cashInHand;
  final double totalWithdrawals;
  final double totalSalesRevenue;
  final double totalPurchaseCost;

  const DashboardFinancialsModel({
    required this.userId,
    this.totalProfit = 0,
    this.totalExpenses = 0,
    this.netProfit = 0,
    this.totalCustomerDebt = 0,
    this.totalSupplierDebt = 0,
    this.cashInHand = 0,
    this.totalWithdrawals = 0,
    this.totalSalesRevenue = 0,
    this.totalPurchaseCost = 0,
  });

  factory DashboardFinancialsModel.fromMap(Map<String, dynamic> map) {
    return DashboardFinancialsModel(
      userId: map['user_id'] as String,
      totalProfit: _toDouble(map['total_profit']),
      totalExpenses: _toDouble(map['total_expenses']),
      netProfit: _toDouble(map['net_profit']),
      totalCustomerDebt: _toDouble(map['total_customer_debt']),
      totalSupplierDebt: _toDouble(map['total_supplier_debt']),
      cashInHand: _toDouble(map['cash_in_hand']),
      totalWithdrawals: _toDouble(map['total_withdrawals']),
      totalSalesRevenue: _toDouble(map['total_sales_revenue']),
      totalPurchaseCost: _toDouble(map['total_purchase_cost']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'total_profit': totalProfit,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'total_customer_debt': totalCustomerDebt,
      'total_supplier_debt': totalSupplierDebt,
      'cash_in_hand': cashInHand,
      'total_withdrawals': totalWithdrawals,
      'total_sales_revenue': totalSalesRevenue,
      'total_purchase_cost': totalPurchaseCost,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [
        userId,
        totalProfit,
        totalExpenses,
        netProfit,
        totalCustomerDebt,
        totalSupplierDebt,
        cashInHand,
        totalWithdrawals,
        totalSalesRevenue,
        totalPurchaseCost,
      ];
}
