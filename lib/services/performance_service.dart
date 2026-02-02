import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';

class PerformanceService extends ChangeNotifier {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Internal state as ValueNotifiers to avoid full service notifyListeners()
  final ValueNotifier<bool> isFpsOverlayEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isHighRefreshEnabledNotifier = ValueNotifier(false);

  bool get isFpsOverlayEnabled => isFpsOverlayEnabledNotifier.value;
  bool get isHighRefreshEnabled => isHighRefreshEnabledNotifier.value;

  double _fps = 0.0;
  double get fps => _fps;

  double _uiTimeMs = 0.0;
  double get uiTimeMs => _uiTimeMs;

  double _gpuTimeMs = 0.0;
  double get gpuTimeMs => _gpuTimeMs;

  final List<FrameTiming> _timings = [];
  Duration? _lastFrameTimestamp;
  DateTime _lastUpdate = DateTime.now();
  final List<double> _fpsBuffer = [];
  static const int _bufferSize = 25;

  bool _isInitialized = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isFpsOverlayEnabledNotifier.value =
        prefs.getBool('dev_fps_overlay') ?? false;
    isHighRefreshEnabledNotifier.value =
        prefs.getBool('dev_high_refresh') ?? true;

    if (!_isInitialized) {
      // Register callbacks ONCE during initialization
      SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      _isInitialized = true;
    }

    if (isHighRefreshEnabled) {
      await FlutterRefreshRateControl().requestHighRefreshRate();
    }
  }

  void toggleFpsOverlay(bool value) {
    isFpsOverlayEnabledNotifier.value = value;

    // Save to prefs without blocking
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('dev_fps_overlay', value);
    });

    if (value) {
      _lastFrameTimestamp = null;
      _fpsBuffer.clear();
      _lastUpdate = DateTime.now();
    }
  }

  void toggleHighRefresh(bool value) async {
    isHighRefreshEnabledNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_high_refresh', value);

    if (value) {
      await FlutterRefreshRateControl().requestHighRefreshRate();
    } else {
      await FlutterRefreshRateControl().stopHighRefreshRate();
    }
  }

  void _onFrame(Duration timestamp) {
    if (!isFpsOverlayEnabled) return;

    if (_lastFrameTimestamp != null) {
      final double delta =
          (timestamp - _lastFrameTimestamp!).inMicroseconds / 1000000.0;
      if (delta > 0) {
        final double instantFps = 1.0 / delta;
        _fpsBuffer.add(instantFps);
        if (_fpsBuffer.length > _bufferSize) _fpsBuffer.removeAt(0);

        // Calculate moving average
        _fps = _fpsBuffer.reduce((a, b) => a + b) / _fpsBuffer.length;

        // Throttle updates to ~5Hz to prevent UI lock
        final now = DateTime.now();
        if (now.difference(_lastUpdate).inMilliseconds > 200) {
          fpsNotifier.value = _fps;
          _lastUpdate = now;
        }
      }
    }
    _lastFrameTimestamp = timestamp;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!isFpsOverlayEnabled) return;

    _timings.addAll(timings);
    if (_timings.length > 50) {
      _timings.removeRange(0, _timings.length - 50);
    }
    _calculateAverages();
  }

  void _calculateAverages() {
    if (_timings.isEmpty) return;

    double totalUi = 0;
    double totalGpu = 0;
    for (var t in _timings) {
      totalUi += t.buildDuration.inMicroseconds / 1000.0;
      totalGpu += t.rasterDuration.inMicroseconds / 1000.0;
    }

    _uiTimeMs = totalUi / _timings.length;
    _gpuTimeMs = totalGpu / _timings.length;
  }

  // Decoupled notifier for FPS to avoid rebuilding entire UI
  final ValueNotifier<double> fpsNotifier = ValueNotifier(0.0);

  @override
  void dispose() {
    fpsNotifier.dispose();
    super.dispose();
  }
}
