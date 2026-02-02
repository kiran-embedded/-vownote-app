import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vownote/services/biometric_service.dart';
import 'package:vownote/utils/haptics.dart';

/// Beautiful Material You lock screen with professional animations
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  late AnimationController _pulseController;
  bool _isAuthenticating = false;
  String _biometricType = 'Biometric';
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _loadBiometricInfo();
    _attemptAuth();
  }

  Future<void> _loadBiometricInfo() async {
    final biometrics = await _biometricService.getAvailableBiometrics();
    setState(() {
      _availableBiometrics = biometrics;
      _biometricType = _biometricService.getBiometricTypeString(biometrics);
    });
  }

  Future<void> _attemptAuth() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);
    Haptics.light();

    try {
      final success = await _biometricService.authenticate();

      if (success && mounted) {
        Haptics.success();
        widget.onUnlocked();
      } else if (mounted) {
        Haptics.error();
        setState(() => _isAuthenticating = false);
      }
    } catch (e) {
      if (mounted) {
        Haptics.error();
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2C2C2E),
                    const Color(0xFF1A1A1A),
                  ]
                : [
                    const Color(0xFFFFFBF5),
                    const Color(0xFFFFF8E1),
                    const Color(0xFFFFFBF5),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App Logo with pulse animation
              AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withOpacity(0.8),
                                const Color(0xFFD4AF37),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 30 + (_pulseController.value * 20),
                                spreadRadius: 5 + (_pulseController.value * 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 60,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      );
                    },
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 40),

              // App Title
              Text(
                    'BizLedger',
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [primaryColor, const Color(0xFFD4AF37)],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOutCubic)
                  .then()
                  .shimmer(duration: 2000.ms, color: const Color(0xFFF5F5F5)),

              const SizedBox(height: 16),

              // Lock Message
              Text(
                'App Locked',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 8),

              Text(
                _isAuthenticating ? 'Authenticating...' : 'Unlock to continue',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

              const Spacer(),

              // Biometric Icon with glow
              GestureDetector(
                    onTap: _attemptAuth,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.1),
                            border: Border.all(
                              color: primaryColor.withOpacity(
                                0.3 + (_pulseController.value * 0.4),
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(
                                  0.2 + (_pulseController.value * 0.3),
                                ),
                                blurRadius: 20 + (_pulseController.value * 15),
                                spreadRadius: 2 + (_pulseController.value * 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getBiometricIcon(),
                            size: 40,
                            color: primaryColor,
                          ),
                        );
                      },
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 2500.ms,
                    color: primaryColor.withOpacity(0.3),
                  )
                  .fadeIn(delay: 800.ms, duration: 600.ms)
                  .scale(
                    delay: 800.ms,
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 24),

              // Unlock button
              TextButton.icon(
                    onPressed: _isAuthenticating ? null : _attemptAuth,
                    icon: Icon(
                      _isAuthenticating
                          ? Icons.hourglass_empty
                          : Icons.lock_open_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _isAuthenticating
                          ? 'Authenticating...'
                          : 'Tap to Unlock with $_biometricType',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 600.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    } else {
      return Icons.lock_outline;
    }
  }
}
