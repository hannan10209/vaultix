import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF7C3AED),
      secondary: const Color(0xFF9F67FF),
      surface: const Color(0xFF1C1C1E),
      error: const Color(0xFFFF453A),
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0D0D0F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D0D0F),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: const BorderSide(color: Color(0xFF2C2C2E), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Color(0xFF636366)),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: Color(0xFF2C2C2E),
      selectedColor: Color(0xFF7C3AED),
      labelStyle: TextStyle(color: Colors.white),
      side: BorderSide.none,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1C1C1E),
      selectedItemColor: Color(0xFF7C3AED),
      unselectedItemColor: Color(0xFF636366),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF2C2C2E),
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
