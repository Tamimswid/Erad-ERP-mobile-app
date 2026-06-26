import 'package:equatable/equatable.dart';

class SupplierDebtModel extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final double totalInvoices;
  final double totalPaid;
  final int totalInvoicesCount;
  final int pendingInvoicesCount;
  final int overdueInvoicesCount;
  final String? latestDueDate;

  const SupplierDebtModel({
    required this.id,
    required this.name,
    this.phone,
    required this.totalInvoices,
    required this.totalPaid,
    this.totalInvoicesCount = 0,
    this.pendingInvoicesCount = 0,
    this.overdueInvoicesCount = 0,
    this.latestDueDate,
  });

  double get remainingDebt => totalInvoices - totalPaid;
  bool get hasDebt => remainingDebt > 0;

  SupplierDebtModel copyWith({
    String? id,
    String? name,
    String? phone,
    double? totalInvoices,
    double? totalPaid,
    int? totalInvoicesCount,
    int? pendingInvoicesCount,
    int? overdueInvoicesCount,
    String? latestDueDate,
  }) {
    return SupplierDebtModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      totalPaid: totalPaid ?? this.totalPaid,
      totalInvoicesCount: totalInvoicesCount ?? this.totalInvoicesCount,
      pendingInvoicesCount: pendingInvoicesCount ?? this.pendingInvoicesCount,
      overdueInvoicesCount: overdueInvoicesCount ?? this.overdueInvoicesCount,
      latestDueDate: latestDueDate ?? this.latestDueDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'total_invoices': totalInvoices,
      'total_paid': totalPaid,
      'total_invoices_count': totalInvoicesCount,
      'pending_invoices_count': pendingInvoicesCount,
      'overdue_invoices_count': overdueInvoicesCount,
      'latest_due_date': latestDueDate,
    };
  }

  factory SupplierDebtModel.fromMap(Map<String, dynamic> map) {
    return SupplierDebtModel(
      id: map['supplier_id'] ?? map['id'] ?? '',
      name: map['supplier_name'] ?? map['name'] ?? '',
      phone: map['phone'],
      totalInvoices: _parseDouble(map['total_invoices'] ?? map['total_debt']),
      totalPaid: _parseDouble(map['total_paid']),
      totalInvoicesCount: map['total_invoices_count'] ?? 0,
      pendingInvoicesCount: map['pending_invoices_count'] ?? 0,
      overdueInvoicesCount: map['overdue_invoices_count'] ?? 0,
      latestDueDate: map['latest_due_date'],
    );
  }

  factory SupplierDebtModel.fromViewMap(Map<String, dynamic> map) {
    return SupplierDebtModel(
      id: map['supplier_id'] ?? '',
      name: map['supplier_name'] ?? '',
      phone: null,
      totalInvoices: _parseDouble(map['total_debt']),
      totalPaid: _parseDouble(map['total_paid']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        totalInvoices,
        totalPaid,
        totalInvoicesCount,
        pendingInvoicesCount,
        overdueInvoicesCount,
        latestDueDate,
      ];
}