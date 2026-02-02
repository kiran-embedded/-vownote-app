import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _useDynamicColors = true; // Enable Material You by default

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get useDynamicColors => _useDynamicColors;

  ThemeService() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    _useDynamicColors = prefs.getBool('use_dynamic_colors') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    notifyListeners();
  }

  Future<void> toggleDynamicColors(bool enabled) async {
    _useDynamicColors = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_dynamic_colors', enabled);
    notifyListeners();
  }
}
