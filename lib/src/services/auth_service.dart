// lib/src/services/auth_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';
import '../services/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _apiBaseUrl = ApiConstants.baseUrl;

  // ====================== SIGN UP ======================
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final idToken = await cred.user?.getIdToken(true);
      if (idToken == null) return false;

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        if (token != null) {
          await StorageService.saveToken(token);
          await StorageService.saveProfile(data['user'] ?? data);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  // ====================== LOGIN (REAL FIX) ======================
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseToken = await cred.user?.getIdToken(true);
      if (firebaseToken == null) return false;

      /// 🔥 IMPORTANT: LOGIN ENDPOINT (NOT /users/)
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/login/'),
        headers: {
          'Authorization': 'Bearer $firebaseToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final drfToken = data['token'];

        if (drfToken != null && drfToken.isNotEmpty) {
          await StorageService.saveToken(drfToken);
          if (data['user'] != null) {
            await StorageService.saveProfile(data['user']);
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // ====================== LOGOUT ======================
  Future<void> logout() async {
    await _auth.signOut();
    await StorageService.clearAll();
  }

  // ====================== UPDATE PROFILE ======================
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$_apiBaseUrl/profiles/me/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        await StorageService.saveProfile(jsonDecode(response.body));
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
