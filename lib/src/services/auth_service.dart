import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiBaseUrl = 'http://10.183.86.156:8000/api'; // For Android emulator; change to Heroku URL later

  // Sign up with email/password and create profile in Django
  Future<String?> signUp(String email, String password, String username) async {
    try {
      print('🔐 Starting sign-up for $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String? idToken = await userCredential.user?.getIdToken();
      print('✅ Firebase sign-up success. ID Token length: ${idToken?.length}');

      if (idToken != null) {
        print('📡 Sending to Django: $_apiBaseUrl/users/');
        print('📦 Body: ${jsonEncode({'username': username})}');
        print('🔑 Header: Bearer ${idToken.substring(0, 20)}...');

        final response = await http.post(
          Uri.parse('$_apiBaseUrl/users/'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'username': username}),
        );

        print('📥 Django Response Status: ${response.statusCode}');
        print('📥 Django Response Body: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          print('✅ Profile created!');
          return idToken;
        } else {
          print('❌ Profile creation failed: ${response.statusCode} - ${response.body}');
        }
      } else {
        print('❌ No ID token received from Firebase');
      }
      return null;
    } catch (e) {
      print('💥 Sign-up error: $e');
      return null;
    }
  }

  // Login with email/password
  Future<String?> login(String email, String password) async {
    try {
      print('🔐 Starting login for $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String? idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        print('✅ Login success. ID Token length: ${idToken.length}');
      } else {
        print('❌ No ID token for login');
      }
      return idToken;
    } catch (e) {
      print('💥 Login error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('Logout successful');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Update profile (example for later use)
  Future<void> updateProfile(String idToken, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/users/1/'), // Replace with dynamic user ID
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