import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final String? categoryName;
  final double amount;
  final String? description;
  final DateTime expenseDate;
  final String paymentMethod;
  final String? receiptNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Expense({
    required this.id,
    required this.userId,
    this.categoryId,
    this.categoryName,
    required this.amount,
    this.description,
    required this.expenseDate,
    this.paymentMethod = 'cash',
    this.receiptNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        categoryName,
        amount,
        description,
        expenseDate,
        paymentMethod,
        receiptNumber,
        notes,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  Expense copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    double? amount,
    String? description,
    DateTime? expenseDate,
    String? paymentMethod,
    String? receiptNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
      'payment_method': paymentMethod,
      'receipt_number': receiptNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      categoryId: map['category_id'],
      categoryName: map['expense_categories'] != null ? map['expense_categories']['name'] : null,
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'],
      expenseDate: DateTime.parse(map['expense_date']),
      paymentMethod: map['payment_method'] ?? 'cash',
      receiptNumber: map['receipt_number'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }
}
