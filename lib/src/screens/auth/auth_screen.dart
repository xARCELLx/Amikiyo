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
  bool _isProcessing = false; // Prevents double tap

  Future<void> _authUser() async {
    if (_isProcessing) return;
    _isProcessing = true;

    if (!mounted) return;

    setState(() => _statusText = 'Processing...');

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && username.isEmpty)) {
      setState(() => _statusText = 'Please fill all fields');
      _isProcessing = false;
      return;
    }

    try {
      String? token;

      if (_isLogin) {
        token = await _authService.login(email: email, password: password);
      } else {
        token = await _authService.signUp(
          email: email,
          password: password,
          username: username,
        );
      }

      if (!mounted) return;

      if (token != null) {
        setState(() => _statusText = 'Success! Redirecting...');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auth successful!'),
            backgroundColor: Color(0xFF00FF7F),
          ),
        );

        // Navigate only if still mounted
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      } else {
        setState(() => _statusText = 'Failed. Check console.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auth failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Error: $e');
      }
    } finally {
      if (mounted) {
        _isProcessing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: const Color(0xFF00FF7F),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isLogin)
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(fontFamily: 'AnimeAce'),
                ),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(fontFamily: 'AnimeAce'),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(fontFamily: 'AnimeAce'),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _authUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF7F),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                _isLogin ? 'Login' : 'Sign Up',
                style: const TextStyle(fontFamily: 'AnimeAce', fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin ? 'Create Account' : 'Have an Account? Login',
                style: const TextStyle(
                  color: Color(0xFF00FF7F),
                  fontFamily: 'AnimeAce',
                  fontSize: 14,
                ),
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