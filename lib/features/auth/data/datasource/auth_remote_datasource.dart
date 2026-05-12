import 'dart:async';
import 'dart:developer';

import 'package:erad/core/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRemoteDataSource {
  Future<User> login(String email, String password);
  Future<User> register({
    required String email,
    required String password,
    required String businessName,
  });

  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String password);
  Future<User> updateProfile(User user);
  Future<void> changePassword(String currentPassword, String newPassword);
  Stream<User?> get userChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthFailure.invalidCredentials();
      }

      final userData = await _getUserData(response.user!.id);
      UserService.saveUserInfo(userId: userData.id, userEmail: userData.email);
      return userData;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw AuthFailure.invalidCredentials();
      } else if (e.message.contains('Email not confirmed')) {
        throw AuthFailure.emailNotVerified();
      } else {
        throw AuthFailure.userNotFound();
      }
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<User> register({
    required String businessName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'business_name': businessName},
      );

      if (response.user == null) {
        throw AuthFailure.emailAlreadyExists();
      }

      final userId = response.user!.id;
      final now = DateTime.now();

      try {
        await client.from('profiles').insert({
          'id': userId,
          'email': email,
          'business_name': businessName,
          'currency_code': 'SAR',
          'language': 'ar',
          'theme_mode': 'light',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      } catch (e) {
        throw exceptionToFailure(e);
      }

      return User(
        id: userId,
        email: email,
        fullName: '',
        phone: '',
        businessName: businessName,
        businessAddress: '',
        taxNumber: '',
        currencyCode: 'SAR',
        language: 'ar',
        themeMode: 'light',
        createdAt: now,
        updatedAt: now,
      );
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw AuthFailure.emailAlreadyExists();
      } else if (e.message.contains('weak_password')) {
        throw AuthFailure.weakPassword();
      } else {
        throw AuthFailure.userNotFound();
      }
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final  userId =  UserService.getUserId();
      return await _getUserData(userId.toString());
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      if (e.message.contains('User not found')) {
        throw AuthFailure.userNotFound();
      } else {
        throw AuthFailure.invalidCredentials();
      }
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> resetPassword(String token, String password) async {
    try {
      await client.auth.verifyOTP(
        token: token,
        type: OtpType.recovery,
        // newPassword: password,
      );
    } on AuthException catch (e) {
      if (e.message.contains('Invalid token')) {
        throw AuthFailure.tokenInvalid();
      } else if (e.message.contains('weak_password')) {
        throw AuthFailure.weakPassword();
      } else {
        throw AuthFailure.tokenInvalid();
      }
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    try {
      await client
          .from('profiles')
          .update({
            'full_name': user.fullName,
            'phone': user.phone,
            'business_name': user.businessName,
            'business_address': user.businessAddress,
            'tax_number': user.taxNumber,
            'currency_code': user.currencyCode,
            'language': user.language,
            'theme_mode': user.themeMode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      return await _getUserData(user.id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw AuthFailure.userNotFound();

      // Verify current password
      await client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      // Update password
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw AuthFailure.invalidCredentials();
      } else if (e.message.contains('weak_password')) {
        throw AuthFailure.weakPassword();
      } else {
        throw AuthFailure.invalidCredentials();
      }
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Stream<User?> get userChanges {
    return client.auth.onAuthStateChange.asyncMap((state) async {
      if (state.session?.user == null) return null;
      return await _getUserData(state.session!.user.id);
    });
  }

  Future<User> _getUserData(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return User.fromMap(response);
    } catch (e) {
      log(e.toString());
      throw ServerFailure.databaseError();
    }
  }
}
