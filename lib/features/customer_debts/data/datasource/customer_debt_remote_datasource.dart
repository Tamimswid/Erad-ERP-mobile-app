import 'dart:async';
import 'dart:developer';

import 'package:erad/core/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';

class CustomerDebtRemoteDataSource {
  final SupabaseClient supabaseClient;

  CustomerDebtRemoteDataSource(this.supabaseClient);

  // جلب جميع ديون العملاء (الفواتير التي لم يتم دفعها)
  Future<List<CustomerDebtModel>> getCustomerDebts() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      // Get only debt invoices (payment_status = 'debt')
      final response = await supabaseClient
          .from('sales_invoices')
          .select('''
            id,
            invoice_number,
            customer_id,
            invoice_date,
            due_date,
            total_amount,
            remaining_amount,
            payment_status,
            status,
            customers!inner(
              name,
              phone
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .eq('payment_status', 'debt')
          .order('invoice_date', ascending: false);

      // Get all payments for customers (only customer type)
      final paymentsResponse = await supabaseClient
          .from('payments')
          .select('customer_id, amount')
          .eq('user_id', userId)
          .eq('payment_type', 'customer')
          .not('customer_id', 'is', null);

      // Calculate total payments per customer
      final customerPayments = <String, double>{};
      for (var json in paymentsResponse as List) {
        final payment = json as Map<String, dynamic>;
        final customerId = payment['customer_id'] as String?;
        if (customerId == null) continue;
        final amount = (payment['amount'] ?? 0.0).toDouble();
        customerPayments[customerId] =
            (customerPayments[customerId] ?? 0.0) + amount;
      }

      // Group invoices by customer_id to show each customer once with total debt
      final customerDebts = <String, CustomerDebtModel>{};

      for (var json in response as List) {
        final invoiceData = json as Map<String, dynamic>;
        final customerId = invoiceData['customer_id'] as String;
        final totalAmount = (invoiceData['total_amount'] ?? 0.0).toDouble();
        // Calculate paid amount from payments table
        final paidAmount = customerPayments[customerId] ?? 0.0;
        final customerData = invoiceData['customers'] as Map<String, dynamic>?;

        if (customerDebts.containsKey(customerId)) {
          // Add to existing customer's debt
          final existing = customerDebts[customerId]!;
          customerDebts[customerId] = CustomerDebtModel(
            id: customerId,
            name: existing.name,
            phone: existing.phone,
            totalInvoices: existing.totalInvoices + totalAmount,
            totalPaid: paidAmount, // Use total from payments table
            totalInvoicesCount: existing.totalInvoicesCount + 1,
            pendingInvoicesCount: existing.pendingInvoicesCount + 1,
            overdueInvoicesCount: existing.overdueInvoicesCount,
            latestDueDate: _getLatestDate(
              existing.latestDueDate,
              invoiceData['due_date'],
            ),
          );
        } else {
          // Create new customer debt entry
          customerDebts[customerId] = CustomerDebtModel(
            id: customerId,
            name: customerData?['name'] ?? 'غير محدد',
            phone: customerData?['phone'],
            totalInvoices: totalAmount,
            totalPaid: paidAmount, // Use total from payments table
            totalInvoicesCount: 1,
            pendingInvoicesCount: 1,
            overdueInvoicesCount: 0,
            latestDueDate: invoiceData['due_date'],
          );
        }
      }

      // Return all customers with debt invoices (including fully paid ones for history)
      return customerDebts.values.toList();
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  String? _getLatestDate(String? current, String? newDate) {
    if (current == null) return newDate;
    if (newDate == null) return current;
    return DateTime.parse(newDate).isAfter(DateTime.parse(current))
        ? newDate
        : current;
  }

  // البحث عن ديون العملاء
  Future<List<CustomerDebtModel>> searchCustomerDebts(String query) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('sales_invoices')
          .select('''
            id,
            invoice_number,
            customer_id,
            invoice_date,
            due_date,
            total_amount,
            remaining_amount,
            payment_status,
            status,
            customers!inner(
              name,
              phone
            )
          ''')
          .eq('user_id', userId)
          .eq('payment_status', 'debt')
          .or('customers.name.ilike.%$query%,invoice_number.ilike.%$query%')
          .order('invoice_date', ascending: false);

      // Get customer IDs from search results
      final Set<String> customerIds = {};
      for (var json in response as List) {
        customerIds.add(
          (json as Map<String, dynamic>)['customer_id'] as String,
        );
      }

      // Get payments for these customers
      final customerPayments = <String, double>{};
      if (customerIds.isNotEmpty) {
        final paymentsResponse = await supabaseClient
            .from('payments')
            .select('customer_id, amount')
            .eq('user_id', userId)
            .inFilter('customer_id', customerIds.toList());

        for (var json in paymentsResponse as List) {
          final payment = json as Map<String, dynamic>;
          final customerId = payment['customer_id'] as String;
          final amount = (payment['amount'] ?? 0.0).toDouble();
          customerPayments[customerId] =
              (customerPayments[customerId] ?? 0.0) + amount;
        }
      }

      // Group invoices by customer_id to show each customer once with total debt
      final customerDebts = <String, CustomerDebtModel>{};

      for (var json in response as List) {
        final invoiceData = json as Map<String, dynamic>;
        final customerId = invoiceData['customer_id'] as String;
        final totalAmount = (invoiceData['total_amount'] ?? 0.0).toDouble();
        // Calculate paid amount from payments table
        final paidAmount = customerPayments[customerId] ?? 0.0;
        final customerData = invoiceData['customers'] as Map<String, dynamic>?;

        if (customerDebts.containsKey(customerId)) {
          // Add to existing customer's debt
          final existing = customerDebts[customerId]!;
          customerDebts[customerId] = CustomerDebtModel(
            id: customerId,
            name: existing.name,
            phone: existing.phone,
            totalInvoices: existing.totalInvoices + totalAmount,
            totalPaid: paidAmount, // Use total from payments table
            totalInvoicesCount: existing.totalInvoicesCount + 1,
            pendingInvoicesCount: existing.pendingInvoicesCount + 1,
            overdueInvoicesCount: existing.overdueInvoicesCount,
            latestDueDate: _getLatestDate(
              existing.latestDueDate,
              invoiceData['due_date'],
            ),
          );
        } else {
          // Create new customer debt entry
          customerDebts[customerId] = CustomerDebtModel(
            id: customerId,
            name: customerData?['name'] ?? 'غير محدد',
            phone: customerData?['phone'],
            totalInvoices: totalAmount,
            totalPaid: paidAmount, // Use total from payments table
            totalInvoicesCount: 1,
            pendingInvoicesCount: 1,
            overdueInvoicesCount: 0,
            latestDueDate: invoiceData['due_date'],
          );
        }
      }

      // Return all customers with debt invoices (including fully paid ones for history)
      return customerDebts.values.toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  // إضافة دفعة جديدة لعميل
  Future<void> addPayment(
    String customerId,
    double amount,
    String? note,
    String paymentDate,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      // إنشاء سجل دفعة مرتبط بالعميل
      await supabaseClient.from('payments').insert({
        'user_id': userId,
        'customer_id': customerId,
        'payment_type': 'customer',
        'amount': amount,
        'payment_date': paymentDate,
        'notes': note,
      });

      log('Payment: Recorded payment of $amount for customer $customerId');

      // Note: paid_amount and remaining_amount columns removed from database
      // Payment status remains 'debt' so invoices always appear in debt list
      // Total paid amount is calculated from payments table when needed
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  // جلب ديون عميل محدد (فواتير العميل غير المدفوعة)
  Future<CustomerDebtModel> getCustomerDebt(String customerId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      // Get only debt invoices for this customer
      final response = await supabaseClient
          .from('sales_invoices')
          .select('''
            id,
            invoice_number,
            customer_id,
            invoice_date,
            due_date,
            total_amount,
            remaining_amount,
            payment_status,
            status,
            customers!inner(
              name,
              phone
            )
          ''')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .eq('payment_status', 'debt')
          .order('invoice_date', ascending: false);

      // Get total payments for this customer
      final paymentsResponse = await supabaseClient
          .from('payments')
          .select('amount')
          .eq('user_id', userId)
          .eq('customer_id', customerId);

      double totalPaidAmount = 0.0;
      for (var json in paymentsResponse as List) {
        totalPaidAmount += (json['amount'] ?? 0.0).toDouble();
      }

      // Group invoices by customer_id to show total debt
      final customerDebts = <String, CustomerDebtModel>{};

      for (var json in response as List) {
        final invoiceData = json as Map<String, dynamic>;
        final currentCustomerId = invoiceData['customer_id'] as String;
        final totalAmount = (invoiceData['total_amount'] ?? 0.0).toDouble();
        final customerData = invoiceData['customers'] as Map<String, dynamic>?;

        if (customerDebts.containsKey(currentCustomerId)) {
          // Add to existing customer's debt
          final existing = customerDebts[currentCustomerId]!;
          customerDebts[currentCustomerId] = CustomerDebtModel(
            id: currentCustomerId,
            name: existing.name,
            phone: existing.phone,
            totalInvoices: existing.totalInvoices + totalAmount,
            totalPaid: totalPaidAmount, // Use total from payments table
            totalInvoicesCount: existing.totalInvoicesCount + 1,
            pendingInvoicesCount: existing.pendingInvoicesCount + 1,
            overdueInvoicesCount: existing.overdueInvoicesCount,
            latestDueDate: _getLatestDate(
              existing.latestDueDate,
              invoiceData['due_date'],
            ),
          );
        } else {
          // Create new customer debt entry
          customerDebts[currentCustomerId] = CustomerDebtModel(
            id: currentCustomerId,
            name: customerData?['name'] ?? 'غير محدد',
            phone: customerData?['phone'],
            totalInvoices: totalAmount,
            totalPaid: totalPaidAmount, // Use total from payments table
            totalInvoicesCount: 1,
            pendingInvoicesCount: 1,
            overdueInvoicesCount: 0,
            latestDueDate: invoiceData['due_date'],
          );
        }
      }

      // Return the customer's total debt
      return customerDebts.values.first;
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  // جلب فواتير العميل (الديون والنقد)
  Future<List<Map<String, dynamic>>> getCustomerInvoices(
    String customerId,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('sales_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .order('invoice_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  // جلب دفعات العميل
  Future<List<Map<String, dynamic>>> getCustomerPayments(
    String customerId,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('payments')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .order('payment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  // حذف دفعة وتحديث الرصيد
  Future<void> deletePayment(
    String paymentId,
    String customerId,
    double amount,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      // حذف سجل الدفعة
      await supabaseClient
          .from('payments')
          .delete()
          .eq('id', paymentId)
          .eq('user_id', userId);

      // تحديث رصيد العميل (إضافة مبلغ الدفعة مرة أخرى)
      await supabaseClient.rpc(
        'update_customer_balance',
        params: {
          'p_customer_id': customerId,
          'p_amount': amount, // Positive to add back to balance
        },
      );
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  // دStream لمتابعة تغييرات رصيد العملاء في الوقت الفعلي
  Stream<List<CustomerDebtModel>> watchCustomerDebts() {
    final controller = StreamController<List<CustomerDebtModel>>();
    List<StreamSubscription> subscriptions = [];

    _fetchAndEmitDebts(controller);

    final userId = UserService.getUserId();

    userId.then((uid) {
      if (uid == null) return;

      final invoiceStream = supabaseClient
          .from('sales_invoices')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid);

      final paymentStream = supabaseClient
          .from('payments')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid);

      subscriptions.add(invoiceStream.listen((_) => _fetchAndEmitDebts(controller)));
      subscriptions.add(paymentStream.listen((_) => _fetchAndEmitDebts(controller)));
    });

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _fetchAndEmitDebts(
    StreamController<List<CustomerDebtModel>> controller,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return;

      // Get only debt invoices
      final response = await supabaseClient
          .from('sales_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('payment_status', 'debt')
          .order('invoice_date', ascending: false);

      // Get all payments for customers
      final customerPayments = <String, double>{};
      final paymentsResponse = await supabaseClient
          .from('payments')
          .select('customer_id, amount')
          .eq('user_id', userId)
          .eq('payment_type', 'customer')
          .not('customer_id', 'is', null);

      for (var json in paymentsResponse as List) {
        final payment = json as Map<String, dynamic>;
        final customerId = payment['customer_id'] as String?;
        if (customerId == null) continue;
        final amount = (payment['amount'] ?? 0.0).toDouble();
        customerPayments[customerId] =
            (customerPayments[customerId] ?? 0.0) + amount;
      }

      // Group by customer_id
      final customerDebts = <String, CustomerDebtModel>{};

      for (var json in response as List) {
        final invoiceData = json as Map<String, dynamic>;
        final customerId = invoiceData['customer_id'] as String;
        final totalAmount = (invoiceData['total_amount'] ?? 0.0).toDouble();
        final paidAmount = customerPayments[customerId] ?? 0.0;

        if (customerDebts.containsKey(customerId)) {
          final existing = customerDebts[customerId]!;
          customerDebts[customerId] = CustomerDebtModel(
            id: customerId,
            name: existing.name,
            phone: existing.phone,
            totalInvoices: existing.totalInvoices + totalAmount,
            totalPaid: paidAmount,
            totalInvoicesCount: existing.totalInvoicesCount + 1,
            pendingInvoicesCount: existing.pendingInvoicesCount + 1,
            overdueInvoicesCount: existing.overdueInvoicesCount,
            latestDueDate: _getLatestDate(
              existing.latestDueDate,
              invoiceData['due_date'],
            ),
          );
        } else {
          customerDebts[customerId] = CustomerDebtModel(
            id: customerId,
            name: 'عميل #$customerId',
            phone: null,
            totalInvoices: totalAmount,
            totalPaid: paidAmount,
            totalInvoicesCount: 1,
            pendingInvoicesCount: 1,
            overdueInvoicesCount: 0,
            latestDueDate: invoiceData['due_date'],
          );
        }
      }

      if (!controller.isClosed) {
        controller.add(customerDebts.values.toList());
      }
    } catch (e) {
      log('Error in _fetchAndEmitDebts: $e');
    }
  }
}
