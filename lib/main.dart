import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ── Your existing imports ─────────────────────────────────────────────────────
import 'src/config/theme.dart';
import 'src/screens/home/home_screen.dart';

// ── New auth imports ───────────────────────────────────────────────────────
import 'src/screens/auth/auth_screen.dart';
import 'src/screens/profile/profile_screen.dart';   // <-- make sure this file exists

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

      // ── 1. Start on the Auth screen ───────────────────────────────────────
      initialRoute: '/auth',

      // ── 2. Named routes (add more later) ───────────────────────────────────
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },

      // ── 3. Optional: simple auth-check wrapper (keeps UI lean) ─────────────
      home: const _AuthWrapper(),
    );
  }
}

/// Small wrapper that decides whether to show Auth or Home
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // You can replace this with a StreamBuilder on FirebaseAuth.instance.authStateChanges()
    // for a production-ready check. For now we just go straight to Auth.
    return const AuthScreen();
  }
}