import 'dart:developer';

import 'package:equatable/equatable.dart';

/// نموذج المدفوعة
/// يمثل دفعة واحدة في نظام الديون
class PaymentModel extends Equatable {
  final String id;
  final String userId;
  final String customerId;
  final String? invoiceId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String? notes;
  final String createdAt;
  final String? updatedAt;
  final String paymentType; // 'customer' or 'supplier'

  const PaymentModel({
    required this.id,
    required this.userId,
    required this.customerId,
    this.invoiceId,
    required this.amount,
    this.paymentMethod = 'نقداً',
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.paymentType = 'customer',
  });

  /// إنشاء نموذج فارغ
  factory PaymentModel.empty() {
    return PaymentModel(
      id: '',
      userId: '',
      customerId: '',
      amount: 0.0,
      paymentDate: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  /// نسخ مع تعديل
  PaymentModel copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? invoiceId,
    double? amount,
    String? paymentMethod,
    String? paymentDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? paymentType,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentType: paymentType ?? this.paymentType,
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'customer_id': customerId,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'payment_type': paymentType,
    };
  }

  /// إنشاء من Map
  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      customerId: map['customer_id'] ?? '',
      invoiceId: map['invoice_id'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['payment_method'] ?? 'نقداً',
      paymentDate: map['payment_date'] ?? map['created_at'] ?? '',
      notes: map['notes'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
      paymentType: map['payment_type'] ?? 'customer',
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() => toMap();

  /// إنشاء من JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      PaymentModel.fromMap(json);

  @override
  List<Object?> get props => [
    id,
    userId,
    customerId,
    invoiceId,
    amount,
    paymentMethod,
    paymentDate,
    notes,
    createdAt,
    updatedAt,
    paymentType,
  ];

  @override
  String toString() {
    return 'PaymentModel(id: $id, amount: $amount, date: $paymentDate)';
  }
}
