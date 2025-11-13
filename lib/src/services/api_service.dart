// lib/src/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.43.1:8000/api'; // YOUR LAPTOP IP

  static Future<Map<String, dynamic>?> getMyProfile() async {
    final token = await StorageService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profiles/me/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await StorageService.saveProfile(data);
        return data;
      } else {
        print('API Error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }
}