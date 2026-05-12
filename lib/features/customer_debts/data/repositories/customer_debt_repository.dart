import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';

abstract class CustomerDebtRepository {
  Future<Either<Failure, List<CustomerDebtModel>>> getCustomerDebts();
  Future<Either<Failure, List<CustomerDebtModel>>> searchCustomerDebts(String query);
  Future<Either<Failure, void>> addPayment(String customerId, double amount, String? note, String paymentDate);
  Future<Either<Failure, CustomerDebtModel>> getCustomerDebt(String customerId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerInvoices(String customerId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerPayments(String customerId);
  Future<Either<Failure, void>> deletePayment(String paymentId, String customerId, double amount);
  // دStream لمتابعة تغييرات رصيد العملاء في الوقت الفعلي
  Stream<Either<Failure, List<CustomerDebtModel>>> watchCustomerDebts();
}
