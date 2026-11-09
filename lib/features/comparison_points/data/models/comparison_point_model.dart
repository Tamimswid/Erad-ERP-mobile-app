import 'package:equatable/equatable.dart';

enum ComparisonPartyType {
  customer('customer'),
  supplier('supplier');

  const ComparisonPartyType(this.value);

  final String value;
}

/// نقطة مطابقة واحدة كما ترجعها view_comparison_points
class ComparisonPointModel extends Equatable {
  final String id;
  final String userId;
  final ComparisonPartyType partyType;
  final String partyId;
  final String partyName;
  final String kind;
  final int sequenceNo;
  final String? label;
  final String? notes;
  final String? anchorInvoiceId;
  final String? anchorInvoiceNumber;
  final String? anchorInvoiceDate;
  final String createdAt;
  final int invoiceCount;
  final double invoiceTotal;
  final int paymentCount;
  final double paymentTotal;
  final double balance;

  const ComparisonPointModel({
    required this.id,
    required this.userId,
    required this.partyType,
    required this.partyId,
    required this.partyName,
    required this.kind,
    required this.sequenceNo,
    this.label,
    this.notes,
    this.anchorInvoiceId,
    this.anchorInvoiceNumber,
    this.anchorInvoiceDate,
    required this.createdAt,
    required this.invoiceCount,
    required this.invoiceTotal,
    required this.paymentCount,
    required this.paymentTotal,
    required this.balance,
  });

  bool get isStart => kind == 'start';

  String get displayName =>
      (label != null && label!.isNotEmpty) ? label! : 'نقطة $sequenceNo';

  factory ComparisonPointModel.fromMap(Map<String, dynamic> map) {
    final type = (map['party_type'] ?? 'customer') as String;
    return ComparisonPointModel(
      id: (map['point_id'] ?? '') as String,
      userId: (map['user_id'] ?? '') as String,
      partyType: type == 'supplier'
          ? ComparisonPartyType.supplier
          : ComparisonPartyType.customer,
      partyId:
          ((type == 'supplier' ? map['supplier_id'] : map['customer_id']) ?? '')
              as String,
      partyName: (map['party_name'] ?? '') as String,
      kind: (map['kind'] ?? 'manual') as String,
      sequenceNo: _toInt(map['sequence_no']),
      label: map['label'] as String?,
      notes: map['notes'] as String?,
      anchorInvoiceId: map['anchor_invoice_id'] as String?,
      anchorInvoiceNumber: map['anchor_invoice_number'] as String?,
      anchorInvoiceDate: map['anchor_invoice_date'] as String?,
      createdAt: (map['created_at'] ?? '') as String,
      invoiceCount: _toInt(map['invoice_count']),
      invoiceTotal: _toDouble(map['invoice_total']),
      paymentCount: _toInt(map['payment_count']),
      paymentTotal: _toDouble(map['payment_total']),
      balance: _toDouble(map['balance']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    partyType,
    partyId,
    partyName,
    kind,
    sequenceNo,
    label,
    notes,
    anchorInvoiceId,
    anchorInvoiceNumber,
    anchorInvoiceDate,
    createdAt,
    invoiceCount,
    invoiceTotal,
    paymentCount,
    paymentTotal,
    balance,
  ];
}
