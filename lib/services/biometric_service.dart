import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling biometric and device lock authentication
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const int _authValidityMinutes =
      5; // Re-auth after 5 minutes (Background only)

  // In-memory session tracking (resets on app kill)
  DateTime? _lastAuthTime;

  /// Check if device supports biometric authentication
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Check if device has any biometrics enrolled
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Check if app lock is enabled
  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  /// Enable/disable app lock
  Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, enabled);
  }

  /// Check if authentication is required (based on last auth time)
  Future<bool> needsAuthentication() async {
    final isEnabled = await isLockEnabled();
    if (!isEnabled) return false;

    // Cold start or cleared auth
    if (_lastAuthTime == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastAuthTime!);

    return difference.inMinutes >= _authValidityMinutes;
  }

  /// Authenticate using biometrics or device credentials
  Future<bool> authenticate() async {
    final canAuthenticate =
        await canUseBiometrics() || await isDeviceSupported();

    if (!canAuthenticate) {
      // Throwing specific error for UI feedback
      throw PlatformException(
        code: 'NotAvailable',
        message: 'Device security is not available. Please set a Screen Lock.',
      );
    }

    final didAuthenticate = await _localAuth.authenticate(
      localizedReason: 'Authenticate to access BizLedger',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false, // Allow PIN/Pattern as fallback
        useErrorDialogs: true,
        sensitiveTransaction: true,
      ),
    );

    if (didAuthenticate) {
      await _updateAuthTime();
    }

    return didAuthenticate;
  }

  /// Update the last authentication time
  Future<void> _updateAuthTime() async {
    _lastAuthTime = DateTime.now();
  }

  /// Clear authentication (for testing or logout)
  Future<void> clearAuth() async {
    _lastAuthTime = null;
  }

  /// Get biometric type string for UI display
  String getBiometricTypeString(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }
}
