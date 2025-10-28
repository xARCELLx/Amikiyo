import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiBaseUrl = 'http:// 10.102.14.156:8000/api'; // For Android emulator; change to Heroku URL later

  // Sign up with email/password and create profile in Django
  Future<String?> signUp(String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String? idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/users/'), // Fixed: Added slash before 'users/'
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'username': username}),
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          print('Profile created: ${response.body}');
          return idToken; // Return JWT for storage
        } else {
          print('Profile creation failed: ${response.statusCode} - ${response.body}');
        }
      }
      return null;
    } catch (e) {
      print('Sign-up error: $e');
      return null;
    }
  }

  // Login with email/password
  Future<String?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String? idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        print('Login successful, ID token: $idToken');
      }
      return idToken;
    } catch (e) {
      print('Login error: $e');
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