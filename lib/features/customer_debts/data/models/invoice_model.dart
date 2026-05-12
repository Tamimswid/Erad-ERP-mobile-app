import 'package:equatable/equatable.dart';

/// نموذج الفاتورة للديون
/// يمثل فاتورة مستحقة في نظام الديون
class InvoiceModel extends Equatable {
  final String id;
  final String userId;
  final String customerId;
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

  const InvoiceModel({
    required this.id,
    required this.userId,
    required this.customerId,
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

  /// إنشاء نموذج فارغ
  factory InvoiceModel.empty() {
    return InvoiceModel(
      id: '',
      userId: '',
      customerId: '',
      invoiceNumber: '',
      invoiceDate: DateTime.now().toIso8601String(),
      totalAmount: 0.0,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  /// هل الفاتورة مستحقة؟
  bool get isDebt =>  paymentStatus == 'debt';

  /// نسخ مع تعديل
  InvoiceModel copyWith({
    String? id,
    String? userId,
    String? customerId,
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
    return InvoiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
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

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'total_amount': totalAmount,
      // 'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// إنشاء من Map
  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      customerId: map['customer_id'] ?? '',
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

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() => toMap();

  /// إنشاء من JSON
  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel.fromMap(json);

  @override
  List<Object?> get props => [
        id,
        userId,
        customerId,
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
    return 'InvoiceModel(id: $id, number: $invoiceNumber, remaining: $remainingAmount)';
  }
}
