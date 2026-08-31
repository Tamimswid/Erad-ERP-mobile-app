import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_financials.dart';
import '../models/dashboard_product_stock.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardFinancialsModel> getFinancials({
    required String startDate,
    required String endDate,
  });
  Future<List<DashboardProductStockModel>> getProductStock();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient client;

  DashboardRemoteDataSourceImpl(this.client);

  @override
  Future<DashboardFinancialsModel> getFinancials({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await client.rpc('get_dashboard_financials', params: {
        'p_user_id': userId,
        'p_start_date': startDate,
        'p_end_date': endDate,
      });

      if (response == null) {
        return DashboardFinancialsModel(userId: userId);
      }

      // RPC tek bir obje döndürebilir veya listede olabilir
      final data = response is List ? response.first : response;
      return DashboardFinancialsModel.fromMap(data as Map<String, dynamic>);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<List<DashboardProductStockModel>> getProductStock() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await client
          .from('dashboard_product_stock')
          .select()
          .eq('user_id', userId);

      return response
          .map((item) => DashboardProductStockModel.fromMap(item))
          .toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }
}
