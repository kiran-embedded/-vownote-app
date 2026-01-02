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
    textTheme: _textTheme
        .copyWith(
          bodyLarge: GoogleFonts.inter(
            color: Colors.black, // Pure black for better contrast
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.inter(
            color: Colors.black87, // Darker grey for better contrast
            fontWeight: FontWeight.w400,
          ),
          displayLarge: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: Colors.black, displayColor: Colors.black),
    iconTheme: const IconThemeData(color: Colors.black),
    dividerTheme: DividerThemeData(color: Colors.black.withOpacity(0.1)),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
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
    textTheme: _textTheme
        .copyWith(
          bodyLarge: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.inter(
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
          displayLarge: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: Colors.white, displayColor: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.1)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
