import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_totals_model.dart';

abstract class SupplierDebtRepository {
  Future<Either<Failure, List<SupplierDebtModel>>> getSupplierDebts();
  Future<Either<Failure, SupplierDebtTotalsModel>> getSupplierDebtTotals();
  Future<Either<Failure, List<SupplierDebtModel>>> searchSupplierDebts(String query);
  Future<Either<Failure, void>> addPayment(String supplierId, double amount, String? note, String paymentDate);
  Future<Either<Failure, SupplierDebtModel>> getSupplierDebt(String supplierId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getSupplierInvoices(String supplierId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getSupplierPayments(String supplierId);
  Future<Either<Failure, void>> deletePayment(String paymentId, String supplierId, double amount);
  Stream<Either<Failure, List<SupplierDebtModel>>> watchSupplierDebts();
}