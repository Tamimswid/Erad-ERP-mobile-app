import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/paged_result.dart';
import '../models/stock_category.dart';
import '../models/stock_review_item.dart';

abstract class StockRemoteDataSource {
  Future<PagedResult<StockReviewItem>> getStockPage({
    required int offset,
    int limit = 10,
    String? search,
    String? categoryId,
  });

  Future<List<StockCategory>> getCategories();
}

class StockRemoteDataSourceImpl implements StockRemoteDataSource {
  StockRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<PagedResult<StockReviewItem>> getStockPage({
    required int offset,
    int limit = 10,
    String? search,
    String? categoryId,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      var query = _client
          .from('dashboard_product_stock')
          .select()
          .eq('user_id', userId);

      if (categoryId != null) {
        final productIds = await _getProductIdsByCategory(userId, categoryId);
        if (productIds.isEmpty) {
          return const PagedResult(items: <StockReviewItem>[], hasMore: false);
        }
        query = query.inFilter('product_id', productIds);
      }

      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        query = query.ilike('product_display_name', '%$term%');
      }

      final response = await query
          .order('product_display_name', ascending: true)
          .order('product_id', ascending: true)
          .range(offset, offset + limit);

      final items = response
          .map((row) => StockReviewItem.fromMap(row))
          .toList();
      final hasMore = items.length > limit;
      return PagedResult(
        items: hasMore ? items.sublist(0, limit) : items,
        hasMore: hasMore,
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<List<StockCategory>> getCategories() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await _client
          .from('categories')
          .select('id, name')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('name');

      return response.map((row) => StockCategory.fromMap(row)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<List<String>> _getProductIdsByCategory(
    String userId,
    String categoryId,
  ) async {
    final response = await _client
        .from('products')
        .select('id')
        .eq('user_id', userId)
        .eq('category_id', categoryId)
        .eq('is_active', true);

    return response.map((row) => row['id'] as String).toList();
  }
}
