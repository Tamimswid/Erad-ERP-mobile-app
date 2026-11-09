import 'package:equatable/equatable.dart';

enum StockMovementType {
  sale,
  purchase,
  adjustment,
  returnSale,
  returnPurchase,
}

class StockMovement extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final StockMovementType movementType;
  final String? referenceId;
  final String? referenceType;
  final int quantityChange;
  final int previousStock;
  final int newStock;
  final double? unitPrice;
  final String? notes;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.userId,
    required this.productId,
    required this.movementType,
    this.referenceId,
    this.referenceType,
    required this.quantityChange,
    required this.previousStock,
    required this.newStock,
    this.unitPrice,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'movement_type': movementType.name,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'quantity_change': quantityChange,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'unit_price': unitPrice,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'] ?? '',
      movementType: StockMovementType.values.firstWhere(
        (e) => e.name == json['movement_type'],
        orElse: () => StockMovementType.adjustment,
      ),
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      quantityChange: json['quantity_change'] ?? 0,
      previousStock: json['previous_stock'] ?? 0,
      newStock: json['new_stock'] ?? 0,
      unitPrice: json['unit_price']?.toDouble(),
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    productId,
    movementType,
    referenceId,
    referenceType,
    quantityChange,
    previousStock,
    newStock,
    unitPrice,
    notes,
    createdAt,
  ];
}
