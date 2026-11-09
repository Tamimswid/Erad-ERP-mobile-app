import 'package:equatable/equatable.dart';

class SupplierModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? city;
  final String? cityId;
  final String? cityName;
  final double currentBalance;
  final double totalPurchases;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.city,
    this.cityId,
    this.cityName,
    required this.currentBalance,
    required this.totalPurchases,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  SupplierModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? city,
    String? cityId,
    String? cityName,
    double? currentBalance,
    double? totalPurchases,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      currentBalance: currentBalance ?? this.currentBalance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'city': city,
      'city_id': cityId,
      'current_balance': currentBalance,
      'total_purchases': totalPurchases,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      city: map['city'],
      cityId: map['city_id'],
      cityName: _cityNameOf(map),
      currentBalance: (map['current_balance'] is String
          ? double.tryParse(map['current_balance']) ?? 0.0
          : (map['current_balance'] as num?)?.toDouble() ?? 0.0),
      totalPurchases: (map['total_purchases'] is String
          ? double.tryParse(map['total_purchases']) ?? 0.0
          : (map['total_purchases'] as num?)?.toDouble() ?? 0.0),
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    phone,
    city,
    cityId,
    cityName,
    currentBalance,
    totalPurchases,
    isActive,
    createdAt,
    updatedAt,
  ];

  /// اسم المدينة القادم من join جدول `cities` أو من نموذج مختصر.
  static String? _cityNameOf(Map<String, dynamic> map) {
    final cities = map['cities'];
    if (cities is Map && cities['name'] != null) {
      return cities['name'] as String;
    }
    return map['city_name'] as String?;
  }
}
