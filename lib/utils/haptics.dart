import 'package:flutter/services.dart';

import 'package:vibration/vibration.dart';

class Haptics {
  static bool _enabled = true;
  static bool _hasCustomVibration = false;

  /// Initialize haptics support
  static Future<void> init() async {
    //Check if device supports custom vibration patterns/amplitude
    _hasCustomVibration = await Vibration.hasCustomVibrationsSupport();
  }

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static bool get isEnabled => _enabled;

  /// Light impact (e.g. keypress, switch)
  /// Simulates a crisp click using 10ms vibration
  static Future<void> light() async {
    if (!_enabled) return;

    if (await Vibration.hasVibrator()) {
      if (_hasCustomVibration) {
        // High-end: Low amplitude, short duration
        Vibration.vibrate(duration: 10, amplitude: 30);
      } else {
        // Low-end: Shortest possible vibration to simulate click
        Vibration.vibrate(duration: 10);
      }
    } else {
      // Fallback
      HapticFeedback.lightImpact();
    }
  }

  /// Medium impact (e.g. success, significant action)
  static Future<void> medium() async {
    if (!_enabled) return;

    if (await Vibration.hasVibrator()) {
      if (_hasCustomVibration) {
        Vibration.vibrate(duration: 20, amplitude: 60);
      } else {
        Vibration.vibrate(duration: 20);
      }
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Heavy impact (e.g. error, delete)
  static Future<void> heavy() async {
    if (!_enabled) return;

    if (await Vibration.hasVibrator()) {
      if (_hasCustomVibration) {
        Vibration.vibrate(duration: 40, amplitude: 128);
      } else {
        Vibration.vibrate(duration: 40);
      }
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  /// Selection click (e.g. scroll, picker)
  /// Extremely short 5ms vibration
  static Future<void> selection() async {
    if (!_enabled) return;

    if (await Vibration.hasVibrator()) {
      // Even on low-end, 5ms feels like a "tick"
      Vibration.vibrate(duration: 5);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Success pattern: Two quick light pulses
  static Future<void> success() async {
    if (!_enabled) return;

    if (await Vibration.hasVibrator()) {
      // bump-bump pattern
      Vibration.vibrate(
        pattern: [0, 10, 80, 10],
        intensities: [0, 255, 0, 150],
      );
    } else {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    }
  }

  /// Error pattern: rapid double shake
  static Future<void> error() async {
    if (!_enabled) return;

    if (await Vibration.hasVibrator()) {
      // bzzz-bzzz pattern
      Vibration.vibrate(
        pattern: [0, 30, 60, 30],
        intensities: [0, 255, 0, 255],
      );
    } else {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> warning() async {
    if (!_enabled) return;
    await medium();
  }
}
