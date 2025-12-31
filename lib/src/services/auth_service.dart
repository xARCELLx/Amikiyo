// lib/src/services/auth_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';
import 'constants.dart';

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
      print('Starting sign-up for $email');

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String? idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        print('No Firebase ID token after sign-up');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'username': username}),
      );

      print('Django signup response: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? drfToken = data['token'];

        if (drfToken != null) {
          await StorageService.saveToken(drfToken);
          await StorageService.saveProfile(data);
          print('SIGN UP SUCCESS → DRF Token saved');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Sign-up error: $e');
      return false;
    }
  }

  // ====================== LOGIN — FIXED FOREVER ======================
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting login for $email');

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) {
        print('No Firebase token after login');
        return false;
      }

      print('Firebase login OK. Getting DRF token from Django...');

      // FIXED: Use /users/ endpoint with Bearer token (same as signUp)
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/'),
        headers: {
          'Authorization': 'Bearer $firebaseToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}), // empty body for login
      );

      print('Django token response: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String? drfToken = data['token'];

        if (drfToken != null && drfToken.isNotEmpty) {
          await StorageService.saveToken(drfToken);
          print('LOGIN SUCCESS → DRF Token saved: ${drfToken.substring(0, 10)}...');

          if (data['user'] != null) {
            await StorageService.saveProfile(data['user']);
          }

          return true;
        }
      }

      print('Failed to get DRF token from server');
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // ====================== LOGOUT ======================
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await StorageService.clearToken();
      await StorageService.clearAll();
      print('Logged out & storage cleared');
    } catch (e) {
      print('Logout error: $e');
    }
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
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}