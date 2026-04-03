import 'package:amikiyo/src/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'src/config/theme.dart';
import 'src/screens/auth/auth_screen.dart';
import 'src/services/storage_service.dart';
import 'src/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 INIT NOTIFICATIONS
  await NotificationService.initialize();

  final token = await StorageService.getToken();

  runApp(AnimeSocialApp(
    initialRoute: token == null ? '/auth' : '/home',
  ));
}

class AnimeSocialApp extends StatelessWidget {
  final String initialRoute;

  const AnimeSocialApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey, // 🔥 IMPORTANT
      title: 'Amikiyo',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}