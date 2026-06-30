import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final TextTheme _textTheme = GoogleFonts.interTextTheme();

  // Default gold color for fallback
  static const Color defaultAccentColor = Color(0xFFD4AF37);

  // iOS 18 / FB Clean Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F2F5), // FB style gray background
    primaryColor: const Color(0xFF9A7B2C), // Deep premium bronze gold for contrast
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9A7B2C),
      primary: const Color(0xFF9A7B2C),
      secondary: const Color(0xFF80621C),
      surface: Colors.white,
      background: const Color(0xFFF0F2F5),
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
        borderRadius: BorderRadius.circular(16), // Softer rectangle for a clean look
        side: BorderSide.none, // No border! Super clean
      ),
    ),
    textTheme: _textTheme
        .copyWith(
          bodyLarge: GoogleFonts.inter(
            color: Colors.black, // Pure black for better contrast
            fontWeight: FontWeight.w500, // Heavier weight
          ),
          bodyMedium: GoogleFonts.inter(
            color: Colors.black, // True black
            fontWeight: FontWeight.w500, // Heavier weight
          ),
          displayLarge: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w800, // Extra bold
          ),
          titleLarge: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w700, // Bold
          ),
        )
        .apply(bodyColor: Colors.black, displayColor: Colors.black),
    iconTheme: const IconThemeData(color: Colors.black),
    dividerTheme: DividerThemeData(color: Colors.black.withOpacity(0.15)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
    ),
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
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.9),
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
