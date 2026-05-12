import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? businessName;
  final String? businessAddress;
  final String? taxNumber;
  final String currencyCode;
  final String language;
  final String themeMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.businessName,
    this.businessAddress,
    this.taxNumber,
    this.currencyCode = 'SAR',
    this.language = 'ar',
    this.themeMode = 'light',
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phone,
        businessName,
        businessAddress,
        taxNumber,
        currencyCode,
        language,
        themeMode,
        createdAt,
        updatedAt,
      ];

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? businessName,
    String? businessAddress,
    String? taxNumber,
    String? currencyCode,
    String? language,
    String? themeMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      taxNumber: taxNumber ?? this.taxNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'business_name': businessName,
      'business_address': businessAddress,
      'tax_number': taxNumber,
      'currency_code': currencyCode,
      'language': language,
      'theme_mode': themeMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      phone: map['phone'] ?? '',
      businessName: map['business_name'] ?? '',
      businessAddress: map['business_address'] ?? '',
      taxNumber: map['tax_number'] ?? '',
      currencyCode: map['currency_code'] ?? 'SAR',
      language: map['language'] ?? 'ar',
      themeMode: map['theme_mode'] ?? 'light',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
