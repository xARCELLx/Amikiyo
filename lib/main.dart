import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for auth state
import 'firebase_options.dart';

// ── Your existing imports ─────────────────────────────────────────────────────
import 'src/config/theme.dart';
import 'src/screens/home/home_screen.dart';

// ── New auth imports ───────────────────────────────────────────────────────
import 'src/screens/auth/auth_screen.dart';
import 'src/screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AnimeSocialApp());
}

class AnimeSocialApp extends StatelessWidget {
  const AnimeSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimeConnect',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,

      // ── 1. Start with AuthWrapper (checks login state) ─────────────────────
      home: const AuthWrapper(),

      // ── 2. Named routes (used by Navigator.pushNamed) ─────────────────────
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

/// Smart wrapper: Auto-redirects logged-in users to ProfileScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading Firebase auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in → go to ProfileScreen
        if (snapshot.hasData) {
          return const ProfileScreen();
        }

        // No user → go to AuthScreen
        return const AuthScreen();
      },
    );
  }
}