import 'package:equatable/equatable.dart';

class DashboardProductStockModel extends Equatable {
  final String userId;
  final String productId;
  final String productName;
  final int systemStock;
  final int totalPurchasedQty;
  final int totalSoldQty;
  final int calculatedRemainingStock;

  const DashboardProductStockModel({
    required this.userId,
    required this.productId,
    required this.productName,
    this.systemStock = 0,
    this.totalPurchasedQty = 0,
    this.totalSoldQty = 0,
    this.calculatedRemainingStock = 0,
  });

  factory DashboardProductStockModel.fromMap(Map<String, dynamic> map) {
    return DashboardProductStockModel(
      userId: map['user_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_display_name'] as String? ?? '',
      systemStock: _toInt(map['system_stock']),
      totalPurchasedQty: _toInt(map['total_purchased_qty']),
      totalSoldQty: _toInt(map['total_sold_qty']),
      calculatedRemainingStock: _toInt(map['calculated_remaining_stock']),
    );
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
        userId,
        productId,
        productName,
        systemStock,
        totalPurchasedQty,
        totalSoldQty,
        calculatedRemainingStock,
      ];
}
