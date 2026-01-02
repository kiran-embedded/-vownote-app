import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final TextTheme _textTheme = GoogleFonts.interTextTheme();

  // iOS 18 Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS Grouped Background
    primaryColor: const Color(0xFFD4AF37), // Gold
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFD4AF37),
      primary: const Color(0xFFD4AF37),
      secondary: const Color(0xFFEAB308),
      surface: Colors.white,
      background: const Color(0xFFF2F2F7),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Pill Shape
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
    ),
    textTheme: _textTheme.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(0.2)),
  );

  // iOS 18 Dark Theme (OLED Friendly)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black, // True Black for OLED
    primaryColor: const Color(0xFFD4AF37),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFD4AF37),
      primary: const Color(0xFFD4AF37),
      secondary: const Color(0xFFEAB308),
      surface: const Color(0xFF1C1C1E), // iOS Dark Grouped Card
      background: Colors.black,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Pill Shape
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
    ),
    textTheme: _textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(0.3)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
    ),
  );
}
