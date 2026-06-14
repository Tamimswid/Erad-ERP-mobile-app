import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_financials.dart';
import '../models/dashboard_product_stock.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardFinancialsModel> getFinancials();
  Future<List<DashboardProductStockModel>> getProductStock();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient client;

  DashboardRemoteDataSourceImpl(this.client);

  @override
  Future<DashboardFinancialsModel> getFinancials() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await client
          .from('dashboard_financials')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return DashboardFinancialsModel(userId: userId);
      }

      return DashboardFinancialsModel.fromMap(response);
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
