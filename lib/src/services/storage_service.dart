// lib/src/services/storage_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Secure storage for TOKEN (encrypted + works on Android 11+)
  static const _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'drf_auth_token';

  // Regular SharedPreferences for non-sensitive data (profile cache)
  static const String _profileKey = 'cached_profile';

  // Save token securely
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    print('TOKEN SAVED SECURELY: ${token.substring(0, 10)}...');
  }

  // Get token securely
  static Future<String?> getToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) {
      print('No token found in secure storage');
    } else {
      print('TOKEN LOADED SECURELY: ${token.substring(0, 10)}...');
    }
    return token;
  }

  // Clear token
  static Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    print('TOKEN CLEARED FROM SECURE STORAGE');
  }

  // Save profile cache (safe to use SharedPreferences)
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile));
    print('Profile cached');
  }

  // Get cached profile
  static Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_profileKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // Clear everything
  static Future<void> clearAll() async {
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    print('All storage cleared');
  }

  // Debug: Check if token exists
  static Future<bool> hasToken() async {
    return await _secureStorage.containsKey(key: _tokenKey);
  }
}