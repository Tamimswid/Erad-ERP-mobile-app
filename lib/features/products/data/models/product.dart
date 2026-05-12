import 'dart:developer';

import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String userId;
  final String code;
  final String? barcode;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String unit;
  final String measurement;
  final double purchasePrice;
  final double salePrice;
  final double minSalePrice;
  final int currentStock;
  final int minStock;
  final int? maxStock;
  final String? location;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ProductModel({
    required this.id,
    required this.userId,
    required this.code,
    this.barcode,
    required this.name,
    this.categoryId,
    this.categoryName,
   required this.unit ,
  required  this.measurement ,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.minSalePrice = 0,
    this.currentStock = 0,
    this.minStock = 0,
    this.maxStock,
    this.location,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        code,
        barcode,
        name,
        categoryId,
        categoryName,
        unit,
        measurement,
        purchasePrice,
        salePrice,
        minSalePrice,
        currentStock,
        minStock,
        maxStock,
        location,
        notes,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  ProductModel copyWith({
    String? id,
    String? userId,
    String? code,
    String? barcode,
    String? name,
    String? categoryId,
    String? categoryName,
    String? unit,
    String? measurement,
    double? purchasePrice,
    double? salePrice,
    double? minSalePrice,
    int? currentStock,
    int? minStock,
    int? maxStock,
    String? location,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      measurement: measurement ?? this.measurement,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      minSalePrice: minSalePrice ?? this.minSalePrice,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final measurementValue = int.parse(measurement);
    log('Measurement value: $measurementValue');
    log('Measurement: $measurement');
    log('Unit: $unit');
    return {
      'user_id': userId,
      'name': name,
      'category_id': categoryId,
      'unit': unit,
      'measurement': measurementValue,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'min_sale_price': minSalePrice,
      'current_stock': currentStock,
      'min_stock': minStock,
      'max_stock': maxStock,
      'location': location,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      code: map['code'] ?? '',
      barcode: map['barcode'],
      name: map['name'] ?? '',
      categoryId: map['category_id'],
      categoryName: map['categories'] != null ? map['categories']['name'] : null,
      unit: map['unit'] ?? 'piece',
      measurement: map['measurement']?.toString() ?? '0',
      purchasePrice: (map['purchase_price'] ?? 0).toDouble(),
      salePrice: (map['sale_price'] ?? 0).toDouble(),
      minSalePrice: (map['min_sale_price'] ?? 0).toDouble(),
      currentStock: map['current_stock'] ?? 0,
      minStock: map['min_stock'] ?? 0,
      maxStock: map['max_stock'],
      location: map['location'],
      notes: map['notes'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  bool get isLowStock => currentStock <= minStock && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  bool get hasMaxStock => maxStock != null && maxStock! > 0;
  double get profitMargin => salePrice - purchasePrice;
  double get profitPercentage => purchasePrice > 0 ? (profitMargin / purchasePrice) * 100 : 0;
  
  /// Helper method to get product name with measurement and unit
  /// Returns: "name + measurement + unit" format
  String get nameWithMeasurementUnit => '$name $measurement $unit';
}
