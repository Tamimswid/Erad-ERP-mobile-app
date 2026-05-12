import 'package:equatable/equatable.dart';

class ProductCategory extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const ProductCategory({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        parentId,
        sortOrder,
        isActive,
        createdAt,
      ];

  ProductCategory copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? parentId,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      parentId: map['parent_id'],
      sortOrder: map['sort_order'] ?? 0,
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
