import 'package:equatable/equatable.dart';

class DashboardDailySummaryModel extends Equatable {
  final DateTime day;
  final double salesRevenue;
  final double salesProfit;
  final int salesQuantity;
  final double debtSales;
  final int invoiceCount;

  const DashboardDailySummaryModel({
    required this.day,
    this.salesRevenue = 0,
    this.salesProfit = 0,
    this.salesQuantity = 0,
    this.debtSales = 0,
    this.invoiceCount = 0,
  });

  factory DashboardDailySummaryModel.fromMap(Map<String, dynamic> map) {
    return DashboardDailySummaryModel(
      day: DateTime.parse(map['day'] as String),
      salesRevenue: _toDouble(map['sales_revenue']),
      salesProfit: _toDouble(map['sales_profit']),
      salesQuantity: _toInt(map['sales_quantity']),
      debtSales: _toDouble(map['debt_sales']),
      invoiceCount: _toInt(map['invoice_count']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [
    day,
    salesRevenue,
    salesProfit,
    salesQuantity,
    debtSales,
    invoiceCount,
  ];
}
