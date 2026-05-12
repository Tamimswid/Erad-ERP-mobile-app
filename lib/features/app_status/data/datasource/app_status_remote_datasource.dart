import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/core/errors/failures.dart';

class AppStatusRemoteDataSource {
  final SupabaseClient supabaseClient;

  AppStatusRemoteDataSource(this.supabaseClient);

  Future<bool> checkAppStatus() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('profiles')
          .select('is_active')
          .eq('id', userId)
          .single();
      return response['is_active'] as bool? ?? false;      
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }
}
