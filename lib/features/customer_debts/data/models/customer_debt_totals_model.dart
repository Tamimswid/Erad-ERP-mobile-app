import 'dart:developer';

import 'package:equatable/equatable.dart';

class CustomerDebtTotalsModel extends Equatable {
  final double totalDebtAll;
  final double totalPaidAll;
  final double totalInvoicesAll;

  const CustomerDebtTotalsModel({
    this.totalDebtAll = 0,
    this.totalPaidAll = 0,
    this.totalInvoicesAll = 0,
  });

  factory CustomerDebtTotalsModel.fromMap(Map<String, dynamic> map) {
    log(map.toString());
    return CustomerDebtTotalsModel(
      totalDebtAll: _parseDouble(map['remaining_balance_all']),
      totalPaidAll: _parseDouble(map['total_paid_all']),
      totalInvoicesAll: _parseDouble(map['total_debt_all']),
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
