import 'package:flutter/material.dart';
import 'package:vownote/services/biometric_service.dart';
import 'package:vownote/ui/lock_screen.dart';

/// Wrapper widget that conditionally shows lock screen or content
class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();
  bool _isLocked = true;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize lock state based on user preference, default to locked if enabled
    _initializeLockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Immediately lock UI when app is paused/backgrounded
      if (mounted) {
        setState(() {
          _isLocked = true;
          _checking = true; // Force re-check on resume
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // Re-validate lock on compliance
      _checkLockStatus();
    }
  }

  Future<void> _initializeLockState() async {
    final enabled = await _biometricService.isLockEnabled();
    if (mounted) {
      setState(() {
        _isLocked = enabled;
        _checking = true;
      });
    }
    await _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    final needsAuth = await _biometricService.needsAuthentication();
    if (mounted) {
      setState(() {
        _isLocked = needsAuth;
        _checking = false;
      });
    }
  }

  void _onUnlocked() {
    if (mounted) {
      setState(() {
        _isLocked = false;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLocked) {
      return LockScreen(onUnlocked: _onUnlocked);
    }

    return widget.child;
  }
}
