import 'package:equatable/equatable.dart';

class CustomerDebtModel extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final double totalInvoices;
  final double totalPaid;
  final int totalInvoicesCount;
  final int pendingInvoicesCount;
  final int overdueInvoicesCount;
  final String? latestDueDate;

  const CustomerDebtModel({
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

  CustomerDebtModel copyWith({
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
    return CustomerDebtModel(
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

  factory CustomerDebtModel.fromMap(Map<String, dynamic> map) {
    return CustomerDebtModel(
      id: map['customer_id'] ?? map['id'] ?? '',
      name: map['customer_name'] ?? map['name'] ?? '',
      phone: map['phone'],
      totalInvoices: (map['total_invoices'] ?? 0.0).toDouble(),
      totalPaid: (map['total_paid'] ?? 0.0).toDouble(),
      totalInvoicesCount: map['total_invoices_count'] ?? 0,
      pendingInvoicesCount: map['pending_invoices_count'] ?? 0,
      overdueInvoicesCount: map['overdue_invoices_count'] ?? 0,
      latestDueDate: map['latest_due_date'],
    );
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
