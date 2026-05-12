import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(User user);
  Future<User?> getCachedUser();
  Future<void> clearCachedUser();
  Future<void> cacheAuthToken(String token);
  Future<String?> getCachedAuthToken();
  Future<void> clearCachedAuthToken();
  Future<void> cacheUserId(String userId);
  Future<String?> getCachedUserId();
  Future<void> clearCachedUserId();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences prefs;

  AuthLocalDataSourceImpl(this.prefs);

  static const String _cachedUserKey = 'CACHED_USER';
  static const String _authTokenKey = 'AUTH_TOKEN';
  static const String _userIdKey = 'USER_ID';

  @override
  Future<void> cacheUser(User user) async {
    try {
      final userJson = json.encode(user.toMap());
      await prefs.setString(_cachedUserKey, userJson);
    } catch (e) {
      throw Exception('Failed to cache user data: $e');
    }
  }

  @override
  Future<User?> getCachedUser() async {
    try {
      final userJson = prefs.getString(_cachedUserKey);
      if (userJson == null) return null;

      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return User.fromMap(userMap);
    } catch (e) {
      throw Exception('Failed to get cached user data: $e');
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      await prefs.remove(_cachedUserKey);
    } catch (e) {
      throw Exception('Failed to clear cached user data: $e');
    }
  }

  @override
  Future<void> cacheAuthToken(String token) async {
    try {
      await prefs.setString(_authTokenKey, token);
    } catch (e) {
      throw Exception('Failed to cache auth token: $e');
    }
  }

  @override
  Future<String?> getCachedAuthToken() async {
    try {
      return prefs.getString(_authTokenKey);
    } catch (e) {
      throw Exception('Failed to get cached auth token: $e');
    }
  }

  @override
  Future<void> clearCachedAuthToken() async {
    try {
      await prefs.remove(_authTokenKey);
    } catch (e) {
      throw Exception('Failed to clear cached auth token: $e');
    }
  }

  @override
  Future<void> cacheUserId(String userId) async {
    try {
      await prefs.setString(_userIdKey, userId);
    } catch (e) {
      throw Exception('Failed to cache user id: $e');
    }
  }

  @override
  Future<String?> getCachedUserId() async {
    try {
      return prefs.getString(_userIdKey);
    } catch (e) {
      throw Exception('Failed to get cached user id: $e');
    }
  }

  @override
  Future<void> clearCachedUserId() async {
    try {
      await prefs.remove(_userIdKey);
    } catch (e) {
      throw Exception('Failed to clear cached user id: $e');
    }
  }
}
