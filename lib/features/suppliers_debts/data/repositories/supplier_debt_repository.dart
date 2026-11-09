import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_totals_model.dart';

abstract class SupplierDebtRepository {
  Future<Either<Failure, PagedResult<SupplierDebtModel>>> getSupplierDebtsPage({
    required int offset,
    int limit,
    String? search,
  });
  Future<Either<Failure, int>> getSupplierDebtCount({String? search});
  Future<Either<Failure, SupplierDebtTotalsModel>> getSupplierDebtTotals();
  Future<Either<Failure, void>> addPayment(
    String supplierId,
    double amount,
    String? note,
    String paymentDate,
  );
  Future<Either<Failure, SupplierDebtModel>> getSupplierDebt(String supplierId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getSupplierInvoices(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, List<Map<String, dynamic>>>> getSupplierPayments(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, PagedResult<Map<String, dynamic>>>>
  getSupplierInvoicesPage(
    String supplierId, {
    required int offset,
    int limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, PagedResult<Map<String, dynamic>>>>
  getSupplierPaymentsPage(
    String supplierId, {
    required int offset,
    int limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, double>> getSupplierInvoiceTotal(String supplierId);
  Future<Either<Failure, double>> getSupplierPaymentTotal(String supplierId);
  Future<Either<Failure, void>> deletePayment(
    String paymentId,
    String supplierId,
    double amount,
  );
}
