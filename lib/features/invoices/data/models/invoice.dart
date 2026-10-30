import 'package:equatable/equatable.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';

enum InvoiceType { sale, purchase }
enum InvoiceStatus { draft, sent, paid, overdue, cancelled,pending }

class Invoice extends Equatable {
  final String id;
  final String invoiceNumber;
  final InvoiceType type;
  final InvoiceStatus status;
  final String customerId;
  final String? supplierId;
  final DateTime issueDate;
  final DateTime? dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double? paidAmount;
  final double? remainingAmount;
  final String? notes;
  final String? terms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? customerName;
  final String? supplierName;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    required this.status,
    required this.customerId,
    this.supplierId,
    required this.issueDate,
    this.dueDate,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.paidAmount,
    this.remainingAmount,
    this.notes,
    this.terms,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.supplierName,
  });

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    InvoiceType? type,
    InvoiceStatus? status,
    String? customerId,
    String? supplierId,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? notes,
    String? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? supplierName,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      supplierName: supplierName ?? this.supplierName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'type': type.name,
      'status': status.name,
      'customer_id': customerId,
      'supplier_id': supplierId,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'notes': notes,
      'terms': terms,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer_name': customerName,
      'supplier_name': supplierName,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      type: InvoiceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InvoiceType.sale,
      ),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      customerId: json['customer_id'] ?? '',
      supplierId: json['supplier_id'],
      issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date']) : DateTime.now(),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxRate: (json['tax_rate'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: json['paid_amount']?.toDouble(),
      remainingAmount: json['remaining_amount']?.toDouble(),
      notes: json['notes'],
      terms: json['terms'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      customerName: json['customer_name'],
      supplierName: json['supplier_name'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        type,
        status,
        customerId,
        supplierId,
        issueDate,
        dueDate,
        items,
        subtotal,
        taxRate,
        taxAmount,
        discountAmount,
        totalAmount,
        paidAmount,
        remainingAmount,
        notes,
        terms,
        createdAt,
        updatedAt,
        customerName,
        supplierName,
      ];
}

