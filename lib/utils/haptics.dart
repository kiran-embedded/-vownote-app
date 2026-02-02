import 'package:flutter/services.dart';
import 'dart:io';

class Haptics {
  static bool _enabled = true;
  static bool _supportsAdvancedHaptics = true;

  /// Initialize haptics support
  static Future<void> init() async {
    if (Platform.isAndroid || Platform.isIOS) {
      _supportsAdvancedHaptics = true;
    } else {
      _supportsAdvancedHaptics = false;
    }
  }

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static bool get isEnabled => _enabled;

  static Future<void> light() async {
    if (!_enabled) return;
    _supportsAdvancedHaptics
        ? await HapticFeedback.lightImpact()
        : await HapticFeedback.vibrate();
  }

  static Future<void> medium() async {
    if (!_enabled) return;
    _supportsAdvancedHaptics
        ? await HapticFeedback.mediumImpact()
        : await HapticFeedback.vibrate();
  }

  static Future<void> heavy() async {
    if (!_enabled) return;
    if (_supportsAdvancedHaptics) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.vibrate();
    }
  }

  static Future<void> selection() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    if (!_enabled) return;
    if (_supportsAdvancedHaptics) {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.vibrate();
    }
  }

  static Future<void> error() async {
    if (!_enabled) return;
    if (_supportsAdvancedHaptics) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.vibrate();
    }
  }

  static Future<void> warning() async {
    if (!_enabled) return;
    await (_supportsAdvancedHaptics
        ? HapticFeedback.mediumImpact()
        : HapticFeedback.vibrate());
  }
}
