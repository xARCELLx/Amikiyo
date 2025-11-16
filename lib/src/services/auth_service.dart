import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ── NEW IMPORTS (make sure these files exist) ─────────────────────────────
import 'storage_service.dart';   // for saveToken & saveProfile
import 'constants.dart';         // for single baseUrl

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Single source of truth — change only in constants.dart
  static const String _apiBaseUrl = ApiConstants.baseUrl;

  // ====================== SIGN UP (with DRF token save) ======================
  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      print('Starting sign-up for $email');

      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String? idToken = await userCredential.user?.getIdToken();
      print('Firebase sign-up success. ID Token length: ${idToken?.length}');

      if (idToken == null) {
        print('No ID token received from Firebase');
        return null;
      }

      print('Sending to Django: $_apiBaseUrl/users/');
      print('Body: ${jsonEncode({'username': username})}');

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'username': username}),
      );

      print('Django Response Status: ${response.statusCode}');
      print('Django Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // SAVE THE DRF TOKEN — this is what ProfileScreen needs!
        final String drfToken = data['token'] as String;
        await StorageService.saveToken(drfToken);
        await StorageService.saveProfile(data);

        print('Profile + User created in Django!');
        print('DRF Token saved: $drfToken');

        return idToken; // still return Firebase token if needed elsewhere
      } else {
        print('Profile creation failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Sign-up error: $e');
      return null;
    }
  }

  // ====================== LOGIN (now syncs with Django too) ======================
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting login for $email');

      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        print('No ID token for login');
        return null;
      }

      print('Login success. Syncing user with Django...');

      // Use email prefix as username (or change logic later)
      final String username = email.split('@').first;

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String drfToken = data['token'] as String;
        await StorageService.saveToken(drfToken);
        await StorageService.saveProfile(data);
        print('Django sync successful on login');
      }

      return idToken;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // ====================== LOGOUT ======================
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await StorageService.saveToken(''); // clear token
      print('Logout successful');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // ====================== UPDATE PROFILE (unchanged) ======================
  Future<void> updateProfile({
    required String idToken,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/users/1/'), // TODO: make dynamic
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print('Profile updated: ${response.body}');
      } else {
        print('Update failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Update error: $e');
    }
  }
}