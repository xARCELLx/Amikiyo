import 'package:flutter/material.dart';
import 'package:amikiyo/src/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLogin = true;

  Future<void> _authUser() async {
    String? token;
    if (_isLogin) {
      token = await _authService.login(_emailController.text, _passwordController.text);
    } else {
      token = await _authService.signUp(_emailController.text, _passwordController.text, _usernameController.text);
    }
    if (token != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auth successful')));
      Navigator.pushReplacementNamed(context, '/profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auth failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: const Color(0xFF00FF7F),
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
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(fontFamily: 'AnimeAce'),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF7F),
              ),
              child: Text(_isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontFamily: 'AnimeAce')),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin ? 'Create Account' : 'Have an account? Login',
                style: const TextStyle(color: Color(0xFF00FF7F), fontFamily: 'AnimeAce'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}