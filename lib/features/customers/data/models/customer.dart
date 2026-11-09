import 'package:equatable/equatable.dart';

class CustomerModel extends Equatable {
  final String id;
  final String userId;
  final String code;
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final String? cityId;
  final String? cityName;
  final double creditLimit;
  final double currentBalance;
  final double totalPurchases;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const CustomerModel({
    required this.id,
    required this.userId,
    required this.code,
    required this.name,
    this.phone,
    this.address,
    this.city,
    this.cityId,
    this.cityName,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.totalPurchases = 0,
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
    name,
    phone,
    address,
    city,
    cityId,
    cityName,
    creditLimit,
    currentBalance,
    totalPurchases,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
  ];

  CustomerModel copyWith({
    String? id,
    String? userId,
    String? code,
    String? name,
    String? phone,
    String? address,
    String? city,
    String? cityId,
    String? cityName,
    double? creditLimit,
    double? currentBalance,
    double? totalPurchases,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'city_id': cityId,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'total_purchases': totalPurchases,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      cityId: map['city_id'],
      cityName: _cityNameOf(map),
      creditLimit: (map['credit_limit'] ?? 0).toDouble(),
      currentBalance: (map['current_balance'] ?? 0).toDouble(),
      totalPurchases: (map['total_purchases'] ?? 0).toDouble(),
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
    );
  }

  bool get hasCreditLimit => creditLimit > 0;
  bool get isOverCreditLimit => hasCreditLimit && currentBalance >= creditLimit;
  double get availableCredit =>
      hasCreditLimit ? creditLimit - currentBalance : 0;

  /// اسم المدينة القادم من join جدول `cities` أو من نموذج مختصر.
  static String? _cityNameOf(Map<String, dynamic> map) {
    final cities = map['cities'];
    if (cities is Map && cities['name'] != null) {
      return cities['name'] as String;
    }
    return map['city_name'] as String?;
  }
}
