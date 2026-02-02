import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final TextTheme _textTheme = GoogleFonts.interTextTheme();

  // Default gold color for fallback
  static const Color defaultAccentColor = Color(0xFFD4AF37);

  /// Create dynamic theme from system color scheme (Material You)
  static ThemeData createDynamicLightTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme =
        dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: defaultAccentColor,
          brightness: Brightness.light,
        );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackground: const Color(0xFFF2F2F7),
      cardColor: Colors.white,
    );
  }

  /// Create dynamic dark theme from system color scheme (Material You)
  static ThemeData createDynamicDarkTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme =
        dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: defaultAccentColor,
          brightness: Brightness.dark,
        );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackground: Colors.black,
      cardColor: const Color(0xFF1C1C1E),
    );
  }

  /// Build theme from color scheme
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color cardColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: colorScheme.primary,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: (isDark ? Colors.white : Colors.grey).withOpacity(0.1),
            width: isDark ? 0.5 : 1,
          ),
        ),
      ),
      textTheme: _textTheme
          .copyWith(
            bodyLarge: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w400,
            ),
            bodyMedium: GoogleFonts.inter(
              color: textColor.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
            displayLarge: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          )
          .apply(bodyColor: textColor, displayColor: textColor),
      iconTheme: IconThemeData(color: textColor),
      dividerTheme: DividerThemeData(color: textColor.withOpacity(0.1)),
      inputDecorationTheme: isDark
          ? InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1C1C1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            )
          : null,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

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
