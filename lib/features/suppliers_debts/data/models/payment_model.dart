import 'package:equatable/equatable.dart';

class SupplierPaymentModel extends Equatable {
  final String id;
  final String userId;
  final String supplierId;
  final String? invoiceId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  const SupplierPaymentModel({
    required this.id,
    required this.userId,
    required this.supplierId,
    this.invoiceId,
    required this.amount,
    this.paymentMethod = 'نقداً',
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory SupplierPaymentModel.empty() {
    return SupplierPaymentModel(
      id: '',
      userId: '',
      supplierId: '',
      amount: 0.0,
      paymentDate: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  SupplierPaymentModel copyWith({
    String? id,
    String? userId,
    String? supplierId,
    String? invoiceId,
    double? amount,
    String? paymentMethod,
    String? paymentDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return SupplierPaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      supplierId: supplierId ?? this.supplierId,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'supplier_id': supplierId,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory SupplierPaymentModel.fromMap(Map<String, dynamic> map) {
    return SupplierPaymentModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      supplierId: map['supplier_id'] ?? '',
      invoiceId: map['invoice_id'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['payment_method'] ?? 'نقداً',
      paymentDate: map['payment_date'] ?? map['created_at'] ?? '',
      notes: map['notes'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory SupplierPaymentModel.fromJson(Map<String, dynamic> json) =>
      SupplierPaymentModel.fromMap(json);

  @override
  List<Object?> get props => [
    id,
    userId,
    supplierId,
    invoiceId,
    amount,
    paymentMethod,
    paymentDate,
    notes,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'SupplierPaymentModel(id: $id, amount: $amount, date: $paymentDate)';
  }
}
