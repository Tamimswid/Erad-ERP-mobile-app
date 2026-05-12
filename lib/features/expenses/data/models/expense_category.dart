import 'package:equatable/equatable.dart';

class ExpenseCategory extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const ExpenseCategory({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        isActive,
        createdAt,
      ];

  ExpenseCategory copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
