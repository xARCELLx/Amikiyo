// lib/src/screens/auth/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:amikiyo/src/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLogin = true;
  String _statusText = '';
  bool _isProcessing = false;

  Future<void> _authUser() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Processing...';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && username.isEmpty)) {
      setState(() {
        _statusText = 'Please fill all fields';
        _isProcessing = false;
      });
      return;
    }

    try {
      bool success = false;

      if (_isLogin) {
        success = await _authService.login(
          email: email,
          password: password,
        );
      } else {
        final result = await _authService.signUp(
          email: email,
          password: password,
          username: username,
        );
        success = result != null;
      }

      if (!mounted) return;

      if (success) {
        setState(() => _statusText = 'Success! Redirecting...');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Amikiyo!'),
            backgroundColor: Color(0xFF00FF7F),
          ),
        );

        // 🔥 CRITICAL FIX
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/home');

      } else {
        setState(() => _statusText = 'Failed. Check credentials.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auth failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = '';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: const Color(0xFF00FF7F),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Text(
              'AMIKIYO',
              style: TextStyle(
                color: Color(0xFF00FF7F),
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                fontFamily: 'AnimeAce',
              ),
            ),
            const SizedBox(height: 60),

            if (!_isLogin)
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Color(0xFF00FF7F)),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Color(0xFF00FF7F)),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Color(0xFF00FF7F)),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _statusText,
              style: TextStyle(
                color: _statusText.contains('Success') ? const Color(0xFF00FF7F) : Colors.red,
                fontSize: 14,
                fontFamily: 'AnimeAce',
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _authUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF7F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                )
                    : Text(
                  _isLogin ? 'LOGIN' : 'SIGN UP',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'AnimeAce',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                style: const TextStyle(color: Color(0xFF00FF7F), fontFamily: 'AnimeAce'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}