import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  // ── Save & Get DRF Token ─────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ── Save & Get Cached Profile (this was missing!) ─────────────────────
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_profile', jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('cached_profile');
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // ── Optional: Clear everything on logout ─────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}