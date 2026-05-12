import 'package:equatable/equatable.dart';

class Withdrawal extends Equatable {
  final String id;
  final String userId;
  final String? partnerId;
  final double amount;
  final String? description;
  final DateTime withdrawalDate;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Withdrawal({
    required this.id,
    required this.userId,
    this.partnerId,
    required this.amount,
    this.description,
    required this.withdrawalDate,
    this.paymentMethod = 'cash',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        partnerId,
        amount,
        description,
        withdrawalDate,
        paymentMethod,
        notes,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  Withdrawal copyWith({
    String? id,
    String? userId,
    String? partnerId,
    double? amount,
    String? description,
    DateTime? withdrawalDate,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Withdrawal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      withdrawalDate: withdrawalDate ?? this.withdrawalDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'partner_id': partnerId,
      'amount': amount,
      'description': description,
      'withdrawal_date': withdrawalDate.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Withdrawal.fromMap(Map<String, dynamic> map) {
    return Withdrawal(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      partnerId: map['partner_id'],
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'],
      withdrawalDate: DateTime.parse(map['withdrawal_date']),
      paymentMethod: map['payment_method'] ?? 'cash',
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }
}
