import 'package:equatable/equatable.dart';

class SupplierDebtTotalsModel extends Equatable {
  final double totalDebtAll;
  final double totalPaidAll;
  final double totalInvoicesAll;

  const SupplierDebtTotalsModel({
    this.totalDebtAll = 0,
    this.totalPaidAll = 0,
    this.totalInvoicesAll = 0,
  });

  factory SupplierDebtTotalsModel.fromMap(Map<String, dynamic> map) {
    return SupplierDebtTotalsModel(
      totalDebtAll: _parseDouble(
          map['remaining_balance_all_suppliers'] ?? map['remaining_balance_all']),
      totalPaidAll: _parseDouble(
          map['total_paid_all_suppliers'] ?? map['total_paid_all']),
      totalInvoicesAll: _parseDouble(
          map['total_debt_all_suppliers'] ?? map['total_debt_all']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [totalDebtAll, totalPaidAll, totalInvoicesAll];
}
