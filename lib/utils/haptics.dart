import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'dart:io';

class Haptics {
  static bool _enabled = true;
  static bool _hasCustomVibration = false;
  static bool _hasVibrator = false;
  static bool _isIOS = Platform.isIOS;

  /// Initialize haptics support
  static Future<void> init() async {
    try {
      _hasVibrator = (await Vibration.hasVibrator()) ?? false;
      _hasCustomVibration = (await Vibration.hasCustomVibrationsSupport()) ?? false;
    } catch (_) {
      _hasCustomVibration = false;
      _hasVibrator = false;
    }
  }

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static bool get isEnabled => _enabled;

  /// Light impact (e.g. keypress, switch, subtle tap)
  static Future<void> light() async {
    if (!_enabled) return;
    if (_isIOS) {
      await HapticFeedback.lightImpact();
      return;
    }
    if (_hasCustomVibration) {
      Vibration.vibrate(duration: 25, amplitude: 60); // Increased for midrange
    } else if (_hasVibrator) {
      Vibration.vibrate(duration: 25);
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// Medium impact (e.g. success, significant action, opening dialogs)
  static Future<void> medium() async {
    if (!_enabled) return;
    if (_isIOS) {
      await HapticFeedback.mediumImpact();
      return;
    }
    if (_hasCustomVibration) {
      Vibration.vibrate(duration: 40, amplitude: 120); // Increased
    } else if (_hasVibrator) {
      Vibration.vibrate(duration: 40);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Heavy impact (e.g. error, delete, major state changes)
  static Future<void> heavy() async {
    if (!_enabled) return;
    if (_isIOS) {
      await HapticFeedback.heavyImpact();
      return;
    }
    if (_hasCustomVibration) {
      Vibration.vibrate(duration: 60, amplitude: 200); // Increased
    } else if (_hasVibrator) {
      Vibration.vibrate(duration: 60);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Selection click (e.g. scroll, picker, tab change)
  static Future<void> selection() async {
    if (!_enabled) return;
    if (_isIOS) {
      await HapticFeedback.selectionClick();
      return;
    }
    if (_hasCustomVibration) {
      Vibration.vibrate(duration: 15, amplitude: 80); // More noticeable tick
    } else if (_hasVibrator) {
      Vibration.vibrate(duration: 15);
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  /// Swipe to dismiss / Slide actions
  static Future<void> slide() async {
    if (!_enabled) return;
    if (_isIOS) {
      await HapticFeedback.lightImpact();
      return;
    }
    if (_hasCustomVibration) {
      Vibration.vibrate(duration: 20, amplitude: 70); // Crisp slide
    } else if (_hasVibrator) {
      Vibration.vibrate(duration: 20);
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// Success pattern: Two quick light pulses
  static Future<void> success() async {
    if (!_enabled) return;
    if (_isIOS) {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
      return;
    }
    if (_hasCustomVibration) {
      Vibration.vibrate(
        pattern: [0, 25, 80, 30],
        intensities: [0, 150, 0, 220],
      );
    } else if (_hasVibrator) {
      Vibration.vibrate(pattern: [0, 30, 80, 40]);
    } else {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
    }
  }

  /// Error pattern: rapid double shake
  static Future<void> error() async {
    if (!_enabled) return;
    if (_isIOS) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
      return;
    }
    if (_hasCustomVibration) {
      Vibration.vibrate(
        pattern: [0, 40, 60, 50],
        intensities: [0, 255, 0, 255],
      );
    } else if (_hasVibrator) {
      Vibration.vibrate(pattern: [0, 50, 60, 60]);
    } else {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> warning() async {
    if (!_enabled) return;
    await medium();
  }
}
