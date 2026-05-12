import 'package:equatable/equatable.dart';

class Partner extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Partner({
    required this.id,
    required this.name,
    this.phone,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, phone, createdAt, updatedAt];

  Partner copyWith({
    String? id,
    String? name,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Partner(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Partner.fromMap(Map<String, dynamic> map) {
    return Partner(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
