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
    DateTime? startDate,
    DateTime? endDate,
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
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await _client.rpc(
        'get_stock_review_page',
        params: {
          'p_start_date': _dateParam(startDate),
          'p_end_date': _dateParam(endDate),
          'p_search': search,
          'p_category_id': categoryId,
          'p_product_ids': null,
          'p_offset': offset,
          'p_limit': limit,
        },
      );

      final rows = (response as List).cast<Map<String, dynamic>>();
      final hasMore = rows.length > limit;
      return PagedResult(
        items: rows
            .take(limit)
            .map((row) => StockReviewItem.fromMap(row))
            .toList(),
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

  String? _dateParam(DateTime? date) {
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
