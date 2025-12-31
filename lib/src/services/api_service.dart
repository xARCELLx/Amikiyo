// lib/src/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'constants.dart';

class ApiService {
  static Future<Map<String, dynamic>?> getMyProfile() async {
    final token = await StorageService.getToken();

    if (token == null) {
      print("No DRF token found! Redirecting to login...");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profiles/me/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await StorageService.saveProfile(data);
        return data;
      } else if (response.statusCode == 401) {
        await StorageService.clearToken();
        print("Token expired → cleared");
        return null;
      } else {
        print("Profile fetch failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Network/Profile error: $e");
      return null;
    }
  }
}