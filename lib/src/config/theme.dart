import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme() {
  return ThemeData(
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    primaryColor: const Color(0xFF00FF7F),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FF7F),
      secondary: Color(0xAF00FF7F),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontFamily: 'AnimeAce',
        color: Colors.white,
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        fontFamily: 'AnimeAce',
        color: Color(0xFFB0BEC5),
        fontSize: 12,
      ),
      titleLarge: TextStyle(
        fontFamily: '',
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1A237E),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00FF7F),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF00FF7F),
      unselectedItemColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF41f943),
      foregroundColor: Colors.white,
    ),
  );
}