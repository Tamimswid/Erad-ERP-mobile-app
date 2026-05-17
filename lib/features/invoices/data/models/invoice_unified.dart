import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';

class Invoice {
  final String id;
  final String userId;
  final String invoiceNumber;
  final String? customerId;
  final String? supplierId;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double taxPercentage;
  final double shippingCost;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final String? notes;
  final bool isFinalized;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? customerName;
  final List<InvoiceItem> items;

  const Invoice({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    this.customerId,
    this.supplierId,
    required this.invoiceDate,
    this.dueDate,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.taxPercentage = 0.0,
    this.shippingCost = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.paymentMethod = 'cash',
   required this.paymentStatus  ,
    this.notes,
    this.isFinalized = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.customerName,
    this.items = const [],
  });

  Invoice copyWith({
    String? id,
    String? userId,
    String? invoiceNumber,
    String? customerId,
    String? supplierId,
    DateTime? invoiceDate,
    DateTime? dueDate,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? taxPercentage,
    double? shippingCost,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    String? notes,
    bool? isFinalized,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? customerName,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      shippingCost: shippingCost ?? this.shippingCost,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      isFinalized: isFinalized ?? this.isFinalized,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'supplier_id': supplierId,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'tax_percentage': taxPercentage,
      'shipping_cost': shippingCost,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus.getArabicName,
      'notes': notes,
      'is_finalized': isFinalized,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'customer_name': customerName,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      customerId: json['customer_id'],
      supplierId: json['supplier_id'],
      invoiceDate: DateTime.parse(json['invoice_date']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      taxPercentage: (json['tax_percentage'] ?? 0).toDouble(),
      shippingCost: (json['shipping_cost'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentStatus: PaymentStatus.fromString(json['payment_status'] ?? 'pending'),
      notes: json['notes'],
      isFinalized: json['is_finalized'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      customerName: json['customer_name'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => InvoiceItem.fromJson(item))
          .toList() ?? [],
    );
  }
}