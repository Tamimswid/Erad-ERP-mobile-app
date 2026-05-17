import 'package:equatable/equatable.dart';

class PurchaseInvoiceModel extends Equatable {
  final String id;
  final String userId;
  final String supplierId;
  final String invoiceNumber;
  final String invoiceDate;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? dueDate;
  final String paymentStatus;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  const PurchaseInvoiceModel({
    required this.id,
    required this.userId,
    required this.supplierId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.dueDate,
    this.paymentStatus = 'debt',
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PurchaseInvoiceModel.empty() {
    return PurchaseInvoiceModel(
      id: '',
      userId: '',
      supplierId: '',
      invoiceNumber: '',
      invoiceDate: DateTime.now().toIso8601String(),
      totalAmount: 0.0,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  bool get isDebt => paymentStatus == 'debt';

  PurchaseInvoiceModel copyWith({
    String? id,
    String? userId,
    String? supplierId,
    String? invoiceNumber,
    String? invoiceDate,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? dueDate,
    String? paymentStatus,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return PurchaseInvoiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      supplierId: supplierId ?? this.supplierId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dueDate: dueDate ?? this.dueDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'total_amount': totalAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PurchaseInvoiceModel.fromMap(Map<String, dynamic> map) {
    return PurchaseInvoiceModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      supplierId: map['supplier_id'] ?? '',
      invoiceNumber: map['invoice_number'] ?? '',
      invoiceDate: map['invoice_date'] ?? '',
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      paidAmount: (map['paid_amount'] ?? 0.0).toDouble(),
      remainingAmount: (map['remaining_amount'] ?? 0.0).toDouble(),
      dueDate: map['due_date'],
      paymentStatus: map['payment_status'] ?? 'debt',
      notes: map['notes'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory PurchaseInvoiceModel.fromJson(Map<String, dynamic> json) =>
      PurchaseInvoiceModel.fromMap(json);

  @override
  List<Object?> get props => [
        id,
        userId,
        supplierId,
        invoiceNumber,
        invoiceDate,
        totalAmount,
        paidAmount,
        remainingAmount,
        dueDate,
        paymentStatus,
        notes,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'PurchaseInvoiceModel(id: $id, number: $invoiceNumber, remaining: $remainingAmount)';
  }
}