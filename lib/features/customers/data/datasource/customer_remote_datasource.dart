import 'dart:async';
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';

abstract class CustomerRemoteDataSource {
  // جلب جميع العملاء
  Future<List<CustomerModel>> getCustomers();
  // دStream للعملاء في الوقت الفعلي
  Stream<List<CustomerModel>> watchCustomers();
  // جلب عميل بالمعرف
  Future<CustomerModel> getCustomer(String id);
  // إنشاء عميل جديد
  Future<CustomerModel> createCustomer(CustomerModel customer);
  // تحديث بيانات العميل
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  // حذف عميل
  Future<void> deleteCustomer(String id);
  // البحث عن العملاء
  Future<List<CustomerModel>> searchCustomers(String query);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final SupabaseClient client;

  CustomerRemoteDataSourceImpl(this.client);

  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      // جلب جميع العملاء مرتبة حسب تاريخ الإنشاء
      final response = await client
          .from('customers')
          .select()
          .order('created_at', ascending: false);

      return response.map((customer) => CustomerModel.fromMap(customer)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Stream<List<CustomerModel>> watchCustomers() async* {
    final userId = await UserService.getUserId();
    
    if (userId == null) throw Exception('User not logged in');

    await for (final data in client
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)) {
      yield data.map((item) => CustomerModel.fromMap(item)).toList();
    }
  }

  @override
  Future<CustomerModel> getCustomer(String id) async {
    try {
      final response = await client
          .from('customers')
          .select()
          .eq('id', id)
          .single();

      return CustomerModel.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      // إدخال عميل جديد في قاعدة البيانات
      final response = await client
          .from('customers')
          .insert(customer.toMap())
          .select()
          .single();
      return CustomerModel.fromMap(response);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final response = await client
          .from('customers')
          .update(customer.toMap())
          .eq('id', customer.id)
          .select()
          .single();

      return CustomerModel.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      // جلب معرفات فواتير البيع المرتبطة بالعميل
      final invoices = await client.from('sales_invoices').select('id').eq('customer_id', id);
      final invoiceIds = invoices.map((e) => e['id'] as String).toList();
      
      // حذف عناصر فواتير البيع المرتبطة
      for (final invoiceId in invoiceIds) {
        await client.from('sales_invoice_items').delete().eq('invoice_id', invoiceId);
      }
      
      // حذف فواتير البيع المرتبطة بالعميل
      await client.from('sales_invoices').delete().eq('customer_id', id);
      // حذف الدفعات المرتبطة بالعميل
      await client.from('payments').delete().eq('customer_id', id);
      // حذف العميل
      await client.from('customers').delete().eq('id', id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      // البحث في الاسم والهاتف والمدينة والعنوان
      final response = await client
          .from('customers')
          .select()
          .or('name.ilike.%$query%,phone.ilike.%$query%,city.ilike.%$query%,address.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((customer) => CustomerModel.fromMap(customer)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }
}
