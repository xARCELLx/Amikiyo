import 'package:flutter/material.dart';
import 'src/config/theme.dart';
import 'src/screens/home/home_screen.dart';

void main() {
  runApp(const AnimeSocialApp());
}

class AnimeSocialApp extends StatelessWidget {
  const AnimeSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimeConnect',
      theme: appTheme(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}