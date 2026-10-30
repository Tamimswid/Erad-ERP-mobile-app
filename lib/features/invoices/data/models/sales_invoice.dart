import 'package:equatable/equatable.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'invoice_status.dart';
import 'payment_status.dart';

class SalesInvoice extends Equatable {
  final String id;
  final String userId;
  final String invoiceNumber;
  final String? customerId;
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
  final InvoiceStatus status;
  final PaymentStatus paymentStatus;
  final String? notes;
  final bool isFinalized;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? customerName;
  final List<InvoiceItem> items;
  final double totalPurchaseAmount;
  final double profit;

  const SalesInvoice({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    this.customerId,
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
   required this.status ,
   required this.paymentStatus,
    this.notes,
    this.isFinalized = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.customerName,
    this.items = const [],
    this.totalPurchaseAmount = 0.0,
    this.profit = 0.0,
  });

  SalesInvoice copyWith({
    String? id,
    String? userId,
    String? invoiceNumber,
    String? customerId,
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
    InvoiceStatus? status,
    PaymentStatus? paymentStatus,
    String? notes,
    bool? isFinalized,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? customerName,
    List<InvoiceItem>? items,
    double? totalPurchaseAmount,
    double? profit,
  }) {
    return SalesInvoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
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
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      isFinalized: isFinalized ?? this.isFinalized,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
      profit: profit ?? this.profit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'subtotal': subtotal.toDouble(),
      'discount_amount': discountAmount.toDouble(),
      'tax_amount': taxAmount.toDouble(),
      'tax_percentage': taxPercentage.toDouble(),
      'shipping_cost': shippingCost.toDouble(),
      'total_amount': totalAmount.toDouble(),
      'paid_amount': paidAmount.toDouble(),
      'remaining_amount': remainingAmount.toDouble(),
      'payment_method': paymentMethod,
      'status': status.name,
      'payment_status': paymentStatus.name,
      'is_finalized': isFinalized,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'customer_name': customerName,
      'total_purchase_amount': totalPurchaseAmount.toDouble(),
      'profit': profit.toDouble(),
      'items': items.map((InvoiceItem item) => item.toJson()).toList(),
    };
  }

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    return SalesInvoice(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      customerId: json['customer_id'],
      invoiceDate: json['invoice_date'] != null ? DateTime.parse(json['invoice_date']) : DateTime.now(),
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
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? ''),
        orElse: () => InvoiceStatus.draft,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (json['payment_status'] ?? ''),
        orElse: () => PaymentStatus.cash,
      ),
      notes: json['notes'],
      isFinalized: json['is_finalized'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      customerName: json['customer_name'],
      totalPurchaseAmount: (json['total_purchase_amount'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      items: (json['items'] as List<dynamic>?)
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
        customerId,
        invoiceDate,
        dueDate,
        subtotal,
        discountAmount,
        taxAmount,
        taxPercentage,
        shippingCost,
        totalAmount,
        paidAmount,
        remainingAmount,
        paymentMethod,
        paymentStatus,
        notes,
        isFinalized,
        createdAt,
        updatedAt,
        deletedAt,
        customerName,
        items,
        totalPurchaseAmount,
        profit,
      ];
}

// class SalesInvoiceItem extends Equatable {
//   final String id;
//   final String invoiceId;
//   final String? productId;
//   final String productName;
//   final String? productCode;
//   final int quantity;
//   final double unitPrice;
//   final double discountAmount;
//   final double discountPercentage;
//   final double totalPrice;
//   final String? notes;
//   final DateTime createdAt;

//   const SalesInvoiceItem({
//     required this.id,
//     required this.invoiceId,
//     this.productId,
//     required this.productName,
//     this.productCode,
//     required this.quantity,
//     required this.unitPrice,
//     this.discountAmount = 0.0,
//     this.discountPercentage = 0.0,
//     required this.totalPrice,
//     this.notes,
//     required this.createdAt,
//   });

//   SalesInvoiceItem copyWith({
//     String? id,
//     String? invoiceId,
//     String? productId,
//     String? productName,
//     String? productCode,
//     int? quantity,
//     double? unitPrice,
//     double? discountAmount,
//     double? discountPercentage,
//     double? totalPrice,
//     String? notes,
//     DateTime? createdAt,
//   }) {
//     return SalesInvoiceItem(
//       id: id ?? this.id,
//       invoiceId: invoiceId ?? this.invoiceId,
//       productId: productId ?? this.productId,
//       productName: productName ?? this.productName,
//       productCode: productCode ?? this.productCode,
//       quantity: quantity ?? this.quantity,
//       unitPrice: unitPrice ?? this.unitPrice,
//       discountAmount: discountAmount ?? this.discountAmount,
//       discountPercentage: discountPercentage ?? this.discountPercentage,
//       totalPrice: totalPrice ?? this.totalPrice,
//       notes: notes ?? this.notes,
//       createdAt: createdAt ?? this.createdAt,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'invoice_id': invoiceId,
//       'product_id': productId,
//       'product_name': productName,
//       'product_code': productCode,
//       'quantity': quantity,
//       'unit_price': unitPrice,
//       'discount_amount': discountAmount,
//       'discount_percentage': discountPercentage,
//       'total_price': totalPrice,
//       'notes': notes,
//       'created_at': createdAt.toIso8601String(),
//     };
//   }

//   factory SalesInvoiceItem.fromJson(Map<String, dynamic> json) {
//     return SalesInvoiceItem(
//       id: json['id'] ?? '',
//       invoiceId: json['invoice_id'] ?? '',
//       productId: json['product_id'],
//       productName: json['product_name'] ?? '',
//       productCode: json['product_code'],
//       quantity: json['quantity'] ?? 1,
//       unitPrice: (json['unit_price'] ?? 0).toDouble(),
//       discountAmount: (json['discount_amount'] ?? 0).toDouble(),
//       discountPercentage: (json['discount_percentage'] ?? 0).toDouble(),
//       totalPrice: (json['total_price'] ?? 0).toDouble(),
//       notes: json['notes'],
//       createdAt: DateTime.parse(json['created_at']),
//     );
//   }

//   @override
//   List<Object?> get props => [
//         id,
//         invoiceId,
//         productId,
//         productName,
//         productCode,
//         quantity,
//         unitPrice,
//         discountAmount,
//         discountPercentage,
//         totalPrice,
//         notes,
//         createdAt,
//       ];
// }
