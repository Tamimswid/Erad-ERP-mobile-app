import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_totals_model.dart';

abstract class CustomerDebtRepository {
  Future<Either<Failure, PagedResult<CustomerDebtModel>>> getCustomerDebtsPage({
    required int offset,
    int limit,
    String? search,
  });
  Future<Either<Failure, int>> getCustomerDebtCount({String? search});
  Future<Either<Failure, CustomerDebtTotalsModel>> getCustomerDebtTotals();
  Future<Either<Failure, void>> addPayment(
    String customerId,
    double amount,
    String? note,
    String paymentDate,
  );
  Future<Either<Failure, CustomerDebtModel>> getCustomerDebt(String customerId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerInvoices(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerPayments(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, PagedResult<Map<String, dynamic>>>>
  getCustomerInvoicesPage(
    String customerId, {
    required int offset,
    int limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, PagedResult<Map<String, dynamic>>>>
  getCustomerPaymentsPage(
    String customerId, {
    required int offset,
    int limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, double>> getCustomerInvoiceTotal(String customerId);
  Future<Either<Failure, double>> getCustomerPaymentTotal(String customerId);
  Future<Either<Failure, void>> deletePayment(
    String paymentId,
    String customerId,
    double amount,
  );
}
