// lib/src/services/storage_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // ───────────────── SECURE STORAGE (TOKEN) ─────────────────

  static const _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'drf_auth_token';

  // ───────────────── SHARED PREFS (NON-SENSITIVE) ─────────────────

  static const String _profileKey = 'cached_profile';

  // 🔥 NEW: user id key
  static const String _userIdKey = 'user_id';

  // ───────────────── TOKEN ─────────────────

  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    print('TOKEN SAVED SECURELY: ${token.substring(0, 10)}...');
  }

  static Future<String?> getToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) {
      print('No token found in secure storage');
    } else {
      print('TOKEN LOADED SECURELY: ${token.substring(0, 10)}...');
    }
    return token;
  }

  static Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    print('TOKEN CLEARED FROM SECURE STORAGE');
  }

  static Future<bool> hasToken() async {
    return await _secureStorage.containsKey(key: _tokenKey);
  }

  // ───────────────── USER ID (🔥 NEW) ─────────────────

  /// Save logged-in user id
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    print('USER ID SAVED: $userId');
  }

  /// Get logged-in user id
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userIdKey);
    if (id == null) {
      print('No user id found in storage');
    } else {
      print('USER ID LOADED: $id');
    }
    return id;
  }

  // ───────────────── PROFILE CACHE ─────────────────

  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile));
    print('Profile cached');

    // 🔥 AUTO-SAVE USER ID IF PRESENT
    if (profile['user_id'] != null) {
      await saveUserId(profile['user_id']);
    }
  }

  static Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_profileKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // ───────────────── CLEAR ALL ─────────────────

  static Future<void> clearAll() async {
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_userIdKey);
    print('All storage cleared');
  }

  /// ───────────────── USERNAME ─────────────────

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
}
