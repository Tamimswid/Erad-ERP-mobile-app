import 'package:equatable/equatable.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';

class PurchaseInvoice extends Equatable {
  final String id;
  final String userId;
  final String invoiceNumber;
  final String? supplierId;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double shippingCost;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final InvoiceStatus status;
  final PaymentStatus paymentStatus;
  final String? notes;
  final bool isFinalized;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? supplierName;
  final String? supplierCityId;
  final String? supplierCityName;
  final List<InvoiceItem> items;

  const PurchaseInvoice({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    this.supplierId,
    required this.invoiceDate,
    this.dueDate,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.shippingCost = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    required this.paymentStatus,
    required this.status,
    this.notes,
    this.isFinalized = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.supplierName,
    this.supplierCityId,
    this.supplierCityName,
    this.items = const [],
  });

  PurchaseInvoice copyWith({
    String? id,
    String? userId,
    String? invoiceNumber,
    String? supplierId,
    DateTime? invoiceDate,
    DateTime? dueDate,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? shippingCost,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    InvoiceStatus? status,
    PaymentStatus? paymentStatus,
    String? notes,
    bool? isFinalized,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? supplierName,
    String? supplierCityId,
    String? supplierCityName,
    List<InvoiceItem>? items,
  }) {
    return PurchaseInvoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierId: supplierId ?? this.supplierId,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      isFinalized: isFinalized ?? this.isFinalized,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      supplierName: supplierName ?? this.supplierName,
      supplierCityId: supplierCityId ?? this.supplierCityId,
      supplierCityName: supplierCityName ?? this.supplierCityName,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'invoice_number': invoiceNumber,
      'supplier_id': supplierId,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'subtotal': subtotal.toDouble(),
      'discount_amount': discountAmount.toDouble(),
      'tax_amount': taxAmount.toDouble(),
      'shipping_cost': shippingCost.toDouble(),
      'total_amount': totalAmount.toDouble(),
      'paid_amount': paidAmount.toDouble(),
      'remaining_amount': remainingAmount.toDouble(),
      'status': status.name,
      'payment_status': paymentStatus.name,
      'is_finalized': isFinalized,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'supplier_name': supplierName,
      'supplier_city_id': supplierCityId,
      'supplier_city_name': supplierCityName,
      'items': items.map((InvoiceItem item) => item.toJson()).toList(),
    };
  }

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoice(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      supplierId: json['supplier_id'],
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'])
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      shippingCost: (json['shipping_cost'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (json['payment_status'] ?? ''),
        orElse: () => PaymentStatus.cash,
      ),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? ''),
        orElse: () => InvoiceStatus.draft,
      ),
      notes: json['notes'],
      isFinalized: json['is_finalized'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      supplierName: json['supplier_name'],
      supplierCityId: json['supplier_city_id'],
      supplierCityName: json['supplier_city_name'],
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    invoiceNumber,
    supplierId,
    invoiceDate,
    dueDate,
    subtotal,
    discountAmount,
    taxAmount,
    shippingCost,
    totalAmount,
    paidAmount,
    remainingAmount,
    paymentStatus,
    notes,
    isFinalized,
    createdAt,
    updatedAt,
    deletedAt,
    supplierName,
    supplierCityId,
    supplierCityName,
    items,
  ];
}
