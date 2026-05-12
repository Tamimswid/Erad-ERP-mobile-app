import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProduct(String id);
  Future<List<ProductCategory>> getCategories();
  Future<ProductCategory> getCategory(String id);
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<ProductCategory> createCategory(ProductCategory category);
  Future<ProductCategory> updateCategory(ProductCategory category);
  Future<void> deleteCategory(String id);
  Future<List<ProductModel>> searchProducts(String query);
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
  
  // Real-time streams
  Stream<List<ProductModel>> watchProducts();
  Stream<List<ProductCategory>> watchCategories();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient client;

  ProductRemoteDataSourceImpl(this.client);

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      final response = await client
          .from('products')
          .select('*, categories(name)')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((product) => ProductModel.fromMap(product)).toList();
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await client
          .from('products')
          .select('*, categories(name)')
          .eq('id', id)
          .single();

      return ProductModel.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<List<ProductCategory>> getCategories() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      log('Loading categories for user: $userId');
      
      final response = await client
          .from('categories')
          .select('id, user_id, name, description, parent_id, sort_order, is_active, created_at')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('name')
          .limit(50); // Limit for better performance

      log('Categories loaded: ${response.length}');
      return response.map((category) => ProductCategory.fromMap(category)).toList();
    } catch (e) {
      log('Error loading categories: ${e.toString()}');
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ProductCategory> getCategory(String id) async {
    try {
      final response = await client
          .from('categories')
          .select()
          .eq('id', id)
          .single();

      return ProductCategory.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await client
          .from('products')
          .upsert(product.toMap(), onConflict: 'id')
          .select('*, categories(name)')
          .single();

      return ProductModel.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await client
          .from('products')
          .update(product.toMap())
          .eq('id', product.id)
          .select('*, categories(name)')
          .single();

      return ProductModel.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      // حذف عناصر فواتير البيع المرتبطة بالمنتج
      await client.from('sales_invoice_items').delete().eq('product_id', id);
      // حذف عناصر فواتير الشراء المرتبطة بالمنتج
      await client.from('purchase_invoice_items').delete().eq('product_id', id);
      // حذف المنتج (soft delete)
      await client.from('products').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ProductCategory> createCategory(ProductCategory category) async {
    try {
      final response = await client
          .from('categories')
          .upsert(category.toMap())
          .select()
          .single();

      return ProductCategory.fromMap(response);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ProductCategory> updateCategory(ProductCategory category) async {
    try {
      final response = await client
          .from('categories')
          .update(category.toMap())
          .eq('id', category.id)
          .select()
          .single();

      return ProductCategory.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await client.from('categories').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await client
          .from('products')
          .select('*, categories(name)')
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%,sku.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((product) => ProductModel.fromMap(product)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await client
          .from('products')
          .select('*, categories(name)')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((product) => ProductModel.fromMap(product)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Stream<List<ProductModel>> watchProducts() async* {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      yield* client
          .from('products')
          .select('*, categories(name)')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .asStream()
          .map((response) => response.map((product) => ProductModel.fromMap(product)).toList());
    } catch (e) {
      log('Error in watchProducts stream: ${e.toString()}');
      throw exceptionToFailure(e);
    }
  }

  @override
  Stream<List<ProductCategory>> watchCategories() async* {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      yield* client
          .from('categories')
          .select('id, user_id, name, description, parent_id, sort_order, is_active, created_at')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('name')
          .limit(50)
          .asStream()
          .map((response) => response.map((category) => ProductCategory.fromMap(category)).toList());
    } catch (e) {
      log('Error in watchCategories stream: ${e.toString()}');
      throw exceptionToFailure(e);
    }
  }
}
