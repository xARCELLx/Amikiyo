// lib/src/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';
import 'constants.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl; // YOUR LAPTOP IP

  static Future<Map<String, dynamic>?> getMyProfile() async {
    final token = await StorageService.getToken();
    print('TRYING TO LOAD TOKEN BEFORE PROFILE FETCH: $token');
    print("Fetching profile with token: ${token?.substring(0, 10)}...");
    if (token == null) {
      print("No DRF token found in storage!");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/me/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      print("Response URL: $baseUrl/profiles/me/"); // ← ADD
      print("Response Status: ${response.statusCode}"); // ← ADD
      print("Response Body: ${response.body}"); // ← ADD

      print("Profile API → Status: ${response.statusCode}");
      print("Profile API → Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await StorageService.saveProfile(data);
        return data;
      } else {
        print("Failed to load profile: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Network error: $e");
      return null;
    }
  }
}