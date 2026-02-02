import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vownote/models/business_type.dart';

/// Service for managing business type configuration
class BusinessService extends ChangeNotifier {
  static final BusinessService _instance = BusinessService._internal();
  factory BusinessService() => _instance;
  BusinessService._internal();

  static const String _businessTypeKey = 'selected_business_type';

  BusinessType _currentType = BusinessType.wedding;
  BusinessConfig _currentConfig = BusinessConfig.fromType(BusinessType.wedding);

  /// Get current business type
  BusinessType get currentType => _currentType;

  /// Get current business configuration
  BusinessConfig get config => _currentConfig;

  /// Initialize the service and load saved business type
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(_businessTypeKey);

    if (savedType != null) {
      _currentType = BusinessConfig.fromJson(savedType);
      _currentConfig = BusinessConfig.fromType(_currentType);
    }
  }

  /// Change the business type
  Future<void> setBusinessType(BusinessType type) async {
    if (_currentType == type) return;

    _currentType = type;
    _currentConfig = BusinessConfig.fromType(type);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessTypeKey, type.name);

    notifyListeners();
  }

  /// Get configuration for a specific type without changing current
  BusinessConfig getConfigFor(BusinessType type) {
    return BusinessConfig.fromType(type);
  }

  /// Check if a specific business type is currently selected
  bool isCurrentType(BusinessType type) {
    return _currentType == type;
  }
}
