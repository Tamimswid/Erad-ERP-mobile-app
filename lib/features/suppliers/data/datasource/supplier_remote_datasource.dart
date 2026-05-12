import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';

abstract class SupplierRemoteDataSource {
  Future<List<SupplierModel>> getSuppliers();
  Stream<List<SupplierModel>> watchSuppliers();
  Future<SupplierModel> getSupplier(String id);
  Future<SupplierModel> createSupplier(SupplierModel supplier);
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);
  Future<List<SupplierModel>> searchSuppliers(String query);
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  final SupabaseClient client;

  SupplierRemoteDataSourceImpl(this.client);

  @override
  Future<List<SupplierModel>> getSuppliers() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      final response = await client
          .from('suppliers')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((supplier) => SupplierModel.fromMap(supplier)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Stream<List<SupplierModel>> watchSuppliers() async* {
    final userId = await UserService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    await for (final data in client
        .from('suppliers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)) {
      yield data.map((item) => SupplierModel.fromMap(item)).toList();
    }
  }

  @override
  Future<SupplierModel> getSupplier(String id) async {
    try {
      final response = await client
          .from('suppliers')
          .select()
          .eq('id', id)
          .single();

      return SupplierModel.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<SupplierModel> createSupplier(SupplierModel supplier) async {
    try {      
      final response = await client
          .from('suppliers')
          .insert(supplier.toMap())
          .select()
          .single();

      return SupplierModel.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    try {
      final response = await client
          .from('suppliers')
          .update(supplier.toMap())
          .eq('id', supplier.id)
          .select()
          .single();

      return SupplierModel.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    try {
      // جلب معرفات فواتير الشراء المرتبطة بالمورد
      final invoices = await client.from('purchase_invoices').select('id').eq('supplier_id', id);
      final invoiceIds = invoices.map((e) => e['id'] as String).toList();
      
      // حذف عناصر فواتير الشراء المرتبطة
      for (final invoiceId in invoiceIds) {
        await client.from('purchase_invoice_items').delete().eq('invoice_id', invoiceId);
      }
      
      // حذف فواتير الشراء المرتبطة بالمورد
      await client.from('purchase_invoices').delete().eq('supplier_id', id);
      // حذف المورد
      await client.from('suppliers').delete().eq('id', id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    try {
      final userId = await UserService.getUserId();      
      final response = await client
          .from('suppliers')
          .select()
          .eq('user_id', userId!)
          .or('name.ilike.%$query%,phone.ilike.%$query%,city.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((supplier) => SupplierModel.fromMap(supplier)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }
}
