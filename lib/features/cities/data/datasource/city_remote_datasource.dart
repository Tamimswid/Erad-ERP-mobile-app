import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../models/city.dart';

abstract class CityRemoteDataSource {
  /// المدن المشتركة بين جميع المستخدمين، مرتبة أبجدياً.
  Future<List<CityModel>> getCities();
}

class CityRemoteDataSourceImpl implements CityRemoteDataSource {
  final SupabaseClient client;

  CityRemoteDataSourceImpl(this.client);

  @override
  Future<List<CityModel>> getCities() async {
    try {
      final response = await client
          .from('cities')
          .select('id, name, is_active')
          .eq('is_active', true)
          .order('name', ascending: true);

      return response.map(CityModel.fromMap).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }
}
