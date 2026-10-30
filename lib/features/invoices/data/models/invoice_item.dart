import 'package:equatable/equatable.dart';
import 'package:erad/features/products/data/models/product.dart';


class InvoiceItem extends Equatable {
  final String? id;
  final String? productId;
  final String? productName;
  final int? quantity;
  final double? unitPrice;
  final double? purchasePrice;
  final double? discountAmount;
  final double? totalPrice;
  final String? unit;  
  final String? measurement;
  final DateTime? createdAt;
   

  const InvoiceItem({
     this.id,
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.purchasePrice = 0.0,
    this.discountAmount = 0.0,
    this.totalPrice,
    this.unit,
    this.measurement,
    this.createdAt,
  });

  InvoiceItem copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? purchasePrice,
    double? discountAmount,
    double? totalPrice,
    String? unit,
    String? measurement,
    DateTime? createdAt,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      unit: unit ?? this.unit,
      measurement: measurement ?? this.measurement,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory InvoiceItem.fromProduct(ProductModel product, int quantity) {
    final unitPrice = product.salePrice;
    final totalPrice = unitPrice * quantity;
    
    return InvoiceItem(
      measurement: product.measurement,
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: unitPrice,
      purchasePrice: product.purchasePrice,
      totalPrice: totalPrice,
      unit: product.unit,
    );
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String?,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      measurement: json['measurement'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice?.toDouble(),
      'purchase_price': purchasePrice?.toDouble(),
      'discount_amount': discountAmount?.toDouble(),
      'total_price': totalPrice?.toDouble(),
      'unit': unit,
      'measurement': measurement,
      'created_at': createdAt?.toIso8601String(),
    };
    
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        quantity,
        unitPrice,
        purchasePrice,
        discountAmount,
        totalPrice,
        unit,
        measurement,
        createdAt,
      ];

        String get nameWithMeasurementUnit => '$productName $measurement $unit';
}
