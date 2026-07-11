import 'package:flutter/material.dart';

/// ADA and color-blind friendly Blues & Yellows theme
final ThemeData bluesYellowsLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF003366), // Dark Blue
  scaffoldBackgroundColor: Color(0xFF002244),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF003366),
    secondary: Color(0xFFFFD700), // Gold
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Color(0xFF003366),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF003366), fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF003366)),
    titleLarge: TextStyle(fontSize: 22, color: Color(0xFF003366), fontWeight: FontWeight.bold),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF003366),
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
  ),
);

final ThemeData bluesYellowsDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF003366),
  scaffoldBackgroundColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF003366),
    secondary: Color(0xFFFFD700),
    surface: Colors.black,
    onPrimary: Colors.white,
    onSecondary: Color(0xFF003366),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 18, color: Color(0xFFFFD700), fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(fontSize: 16, color: Color(0xFFFFD700)),
    titleLarge: TextStyle(fontSize: 22, color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF003366),
    foregroundColor: Color(0xFFFFD700),
    titleTextStyle: TextStyle(fontSize: 22, color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
  ),
);
