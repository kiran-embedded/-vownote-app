import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vownote/services/backup_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vownote/utils/branding_utils.dart';
import 'package:vownote/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vownote/main.dart';
import 'package:vownote/services/theme_service.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:vownote/services/performance_service.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vownote/services/business_service.dart';
import 'package:vownote/models/business_type.dart';
import 'package:vownote/ui/help_center_screen.dart';
import 'package:vownote/services/biometric_service.dart';
import 'package:vownote/ui/widgets/shimmer_text.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;

  // Export Settings
  bool _showMoneyInPdf = true;
  bool _showBrideGroom = true;
  bool _showPhone = true;
  bool _showAddress = true;
  bool _showDiary = true;
  bool _use4K = true;

  // Security Settings (Local State for instant toggle)
  bool _isLockEnabled = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Security State
    final lockEnabled = await BiometricService().isLockEnabled();
    final canAuth =
        await BiometricService().isDeviceSupported() ||
        await BiometricService().canUseBiometrics();

    if (mounted) {
      setState(() {
        _showMoneyInPdf = prefs.getBool('show_money_in_pdf') ?? true;
        _showBrideGroom = prefs.getBool('show_names_in_export') ?? true;
        _showPhone = prefs.getBool('show_phone_in_export') ?? true;
        _showAddress = prefs.getBool('show_address_in_export') ?? true;
        _showDiary = prefs.getBool('show_diary_in_export') ?? true;
        _use4K = prefs.getBool('use_4k_screenshots') ?? true;

        // Security
        _isLockEnabled = lockEnabled;
        _canUseBiometrics = canAuth; // Broader check
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    Haptics.light();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'show_money_in_pdf') _showMoneyInPdf = value;
      if (key == 'show_names_in_export') _showBrideGroom = value;
      if (key == 'show_phone_in_export') _showPhone = value;
      if (key == 'show_address_in_export') _showAddress = value;
      if (key == 'show_diary_in_export') _showDiary = value;
      if (key == 'use_4k_screenshots') _use4K = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: ShimmerText(
          tr('settings'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              physics: const BouncingScrollPhysics(),
              children:
                  [
                        _buildBusinessTypeSection(),
                        _buildAppSection(),
                        _buildLanguageSection(),
                        _buildSecuritySection(),
                        _buildExportSettings(),
                        _buildBackupSection(),
                        _buildStorageStatusSection(),
                        const SizedBox(height: 24),
                        _buildHelpBanner(),
                        const SizedBox(height: 40),
                        _buildFooter(),
                        const SizedBox(height: 40),
                      ]
                      .animate(interval: 50.ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            ),
            if (_isLoading)
              Container(
                color: Colors.black12,
                child: const Center(child: CupertinoActivityIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  // Helper for dynamic text color logic
  Color _getTextColor(BuildContext context) {
    // If Material You is active (e.g. dynamic colors), use primary color
    // effective only in light mode or if user wants accent color.
    // However, user requested: "from export settings ui to storage active textes are black at darktheme change
    // to material ui if enabled if material ui off change that text to white"

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final useMaterial = themeService.useDynamicColors;

    if (useMaterial) {
      return theme.colorScheme.primary;
    } else {
      return isDark ? Colors.white : Colors.black;
    }
  }

  Widget _buildPillSection({
    required String title,
    required List<Widget> children,
    Widget? footer,
  }) {
    // Use dynamic logic for color (light text for dark mode, dark text for light mode)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF1C1C1E)
        : theme.colorScheme.surfaceContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor, // Dynamic Material Color
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.1),
                  ),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              child: footer,
            ),
          ),
      ],
    );
  }

  Future<void> _changeBusinessType(BusinessType type) async {
    Haptics.selection();

    final config = BusinessConfig.fromType(type);
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Change to ${config.displayName}?'),
        content: Text(
          'This will update the app to use ${config.displayName.toLowerCase()} terminology and settings.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BusinessService().setBusinessType(type);
      Haptics.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Business type changed to ${config.displayName}'),
            backgroundColor: config.accentColor,
          ),
        );
      }
    }
  }

  Widget _buildBusinessTypeSection() {
    return _buildPillSection(
      title: 'BUSINESS TYPE',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: BusinessService(),
            builder: (context, _) {
              final businessService = BusinessService();
              final currentType = businessService.currentType;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your business type to customize the app',
                    style: TextStyle(
                      fontSize: 13,
                      color: _getTextColor(context).withOpacity(0.7), // Dynamic
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: BusinessType.values.map((type) {
                      final config = BusinessConfig.fromType(type);
                      final isSelected = currentType == type;

                      return GestureDetector(
                        onTap: () => _changeBusinessType(type),
                        child:
                            Container(
                                  width:
                                      (MediaQuery.of(context).size.width - 70) /
                                      2,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? config.accentColor.withOpacity(0.15)
                                        : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF2C2C2E)
                                              : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? config.accentColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                            config.primaryIcon,
                                            size: 28,
                                            color: isSelected
                                                ? config.accentColor
                                                : _getTextColor(
                                                    context,
                                                  ).withOpacity(
                                                    0.5,
                                                  ), // Fixed visibility
                                          )
                                          .animate(target: isSelected ? 1 : 0)
                                          .scale(
                                            duration: 300.ms,
                                            curve: Curves.easeOutBack,
                                          )
                                          .then(delay: 200.ms)
                                          // Fix: Apply shimmer correctly without breaking the chain or using invalid params
                                          .shimmer(
                                            duration: 1200.ms,
                                            color: config.accentColor,
                                          ),
                                      const SizedBox(height: 8),
                                      Text(
                                        config.displayName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? config.accentColor
                                              // Fix: Use global text color logic for unselected items
                                              : _getTextColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(target: isSelected ? 1 : 0)
                                .scale(
                                  duration: 200.ms,
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.02, 1.02),
                                )
                                .shimmer(
                                  duration: 2000.ms,
                                  color: Colors.white.withOpacity(0.2),
                                ), // Pill Shimmer
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppSection() {
    // global themeService is imported from main.dart
    return _buildPillSection(
      title: tr('app').toUpperCase(),
      children: [
        AnimatedBuilder(
          animation: themeService,
          builder: (context, _) {
            final isDark = themeService.themeMode == ThemeMode.dark;
            return CupertinoListTile(
              leading:
                  Icon(
                    isDark
                        ? CupertinoIcons.moon_fill
                        : CupertinoIcons.sun_max_fill,
                    color: isDark ? Colors.purpleAccent : Colors.orange,
                  ).animate().scale(
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  ), // Animate Icon
              title: Text(
                'Dark Mode',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context),
                ),
              ),
              trailing: CupertinoSwitch(
                value: isDark,
                onChanged: (value) {
                  Haptics.selection();
                  themeService.toggleTheme(value);
                },
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: themeService,
          builder: (context, _) {
            return CupertinoListTile(
              leading: Icon(
                Icons.palette_outlined,
                color: Theme.of(context).colorScheme.primary,
              ).animate().rotate(duration: 500.ms), // Animate Icon
              title: Text(
                'Material You',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context),
                ),
              ),
              subtitle: Text(
                'Use wallpaper colors',
                style: TextStyle(
                  color: _getTextColor(context).withOpacity(0.7),
                ),
              ),
              trailing: CupertinoSwitch(
                value: themeService.useDynamicColors,
                activeTrackColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  Haptics.light();
                  themeService.toggleDynamicColors(value);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: GestureDetector(
        onLongPress: () {
          Haptics.heavy();
          _showDevOptions();
        },
        child: Column(
          children: [
            ShimmerText(
              'BizLedger Studio Manager',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              shimmerColors: const [Colors.grey, Colors.white, Colors.grey],
            ),
            const SizedBox(height: 4),
            Text(
              'Version 2.3.0',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const GitHubWatermark(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSettings() {
    return _buildPillSection(
      title: tr('export_settings').toUpperCase(),
      children: [
        _buildCupertinoSwitchTile(
          tr('show_diary'),
          _showDiary,
          (v) => _updateSetting('show_diary_in_export', v),
          icon: CupertinoIcons.book,
          color: Colors.purple,
        ),
        _buildCupertinoSwitchTile(
          tr('show_names'),
          _showBrideGroom,
          (v) => _updateSetting('show_names_in_export', v),
          icon: CupertinoIcons.person_2,
          color: Colors.blue,
        ),
        _buildCupertinoSwitchTile(
          tr('show_phone'),
          _showPhone,
          (v) => _updateSetting('show_phone_in_export', v),
          icon: CupertinoIcons.phone,
          color: Colors.orange,
        ),
        _buildCupertinoSwitchTile(
          tr('show_address'),
          _showAddress,
          (v) => _updateSetting('show_address_in_export', v),
          icon: CupertinoIcons.location,
          color: Colors.redAccent,
        ),
        _buildCupertinoSwitchTile(
          tr('money_in_pdf'),
          _showMoneyInPdf,
          (v) => _updateSetting('show_money_in_pdf', v),
          icon: CupertinoIcons.money_dollar,
          color: Colors.green,
        ),
        _buildCupertinoSwitchTile(
          tr('screenshot_4k'),
          _use4K,
          (v) => _updateSetting('use_4k_screenshots', v),
          icon: CupertinoIcons.camera,
          color: const Color(0xFFD4AF37),
        ),
      ],
    );
  }

  Widget _buildCupertinoSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    required IconData icon,
    required Color color,
  }) {
    return CupertinoListTile(
      leading: Icon(icon, color: color)
          .animate(target: value ? 1 : 0)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.1, 1.1),
            duration: 200.ms,
          )
          .then()
          .scale(
            begin: const Offset(1.1, 1.1),
            end: const Offset(1.0, 1.0),
            duration: 100.ms,
          ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: _getTextColor(context),
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFD4AF37),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _buildPillSection(
      title: tr('language').toUpperCase(),
      children: [
        _buildLanguageTile('English 🇬🇧', 'en'),
        _buildLanguageTile('Malayalam ഭാഷ', 'ml'),
        _buildLanguageTile('हिन्दी 🇮🇳', 'hi'),
        _buildLanguageTile('தமிழ் 🇮🇳', 'ta'),
        _buildLanguageTile('Español 🇪🇸', 'es'),
        _buildLanguageTile('Français 🇫🇷', 'fr'),
        _buildLanguageTile('العربية 🇸🇦', 'ar'),
        _buildLanguageTile('Deutsch 🇩🇪', 'de'),
        _buildLanguageTile('Indonesia 🇮🇩', 'id'),
        _buildLanguageTile('Português 🇵🇹', 'pt'),
      ],
    );
  }

  Widget _buildLanguageTile(String label, String code) {
    final isSelected = LocalizationService().currentLanguage == code;
    return CupertinoListTile(
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: _getTextColor(context), // Dynamic color fix
        ),
      ),
      trailing: isSelected
          ? const Icon(CupertinoIcons.check_mark, color: Color(0xFFD4AF37))
                .animate()
                .scale(duration: 200.ms, curve: Curves.easeOutBack)
                .fadeIn()
          : null,
      backgroundColor: isSelected
          ? const Color(0xFFD4AF37).withOpacity(0.1)
          : null,
      onTap: () async {
        Haptics.selection();
        if (LocalizationService().currentLanguage != code) {
          await LocalizationService().setLanguage(code);
          setState(() {});
        }
      },
    );
  }

  Widget _buildSecuritySection() {
    // Determine color based on availability
    final iconColor = _canUseBiometrics ? const Color(0xFFD4AF37) : Colors.grey;

    return _buildPillSection(
      title: 'SECURITY',
      children: [
        CupertinoListTile(
          leading: Icon(Icons.lock_outline, color: iconColor)
              .animate(target: _isLockEnabled ? 1 : 0)
              .shake(hz: 4, curve: Curves.easeInOut), // Check animation
          title: Text(
            'App Lock',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: _canUseBiometrics
              ? Text(
                  'Biometric & Device Authentication',
                  style: TextStyle(
                    color: _getTextColor(context).withOpacity(0.7),
                  ),
                )
              : const Text(
                  'Device security not available',
                  style: TextStyle(color: Colors.grey),
                ),
          trailing: CupertinoSwitch(
            value: _isLockEnabled, // Allow toggle even if just for PIN
            activeTrackColor: const Color(0xFFD4AF37),
            onChanged: (value) async {
              // Remove strict check here, let authenticate handle it
              Haptics.light();

              if (value) {
                // Enable logic
                try {
                  final success = await BiometricService().authenticate();
                  if (success) {
                    await BiometricService().setLockEnabled(true);
                    Haptics.success();
                    setState(() => _isLockEnabled = true);
                  } else {
                    Haptics.error();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Authentication failed. App lock not enabled.',
                          ),
                        ),
                      );
                    }
                    setState(() => _isLockEnabled = false);
                  }
                } catch (e) {
                  if (mounted) {
                    final message = e is PlatformException
                        ? 'Auth Error: ${e.code} - ${e.message}'
                        : 'Error: $e';

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                }
              } else {
                // Disable logic
                await BiometricService().setLockEnabled(false);
                await BiometricService().clearAuth();
                Haptics.medium();
                setState(() => _isLockEnabled = false);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSection() {
    return _buildPillSection(
      title: 'DATA BACKUP & RESTORE',
      children: [
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.share_up,
            color: CupertinoColors.activeBlue,
          ),
          title: Text(
            'Export Backup',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: Text(
            'Save database as JSON',
            style: TextStyle(color: _getTextColor(context).withOpacity(0.7)),
          ),
          onTap: () async {
            setState(() => _isLoading = true);
            try {
              await _backupService.exportBackup();
              Haptics.success();
            } catch (e) {
              Haptics.medium();
            } finally {
              setState(() => _isLoading = false);
            }
          },
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.arrow_down_doc,
            color: CupertinoColors.activeGreen,
          ),
          title: Text(
            'Import Backup',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: Text(
            'Restore from JSON',
            style: TextStyle(color: _getTextColor(context).withOpacity(0.7)),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Restore Backup?'),
                content: const Text(
                  'This will merge bookings with current list.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Import'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              setState(() => _isLoading = true);
              try {
                await _backupService.importBackup();
                Haptics.success();
              } catch (e) {
                Haptics.medium();
              } finally {
                setState(() => _isLoading = false);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildStorageStatusSection() {
    return FutureBuilder<bool>(
      future: Permission.manageExternalStorage.isGranted,
      builder: (context, snapshot) {
        final isGranted = snapshot.data ?? false;
        return _buildPillSection(
          title: 'GLOBAL PERSISTENCE',
          children: [
            CupertinoListTile(
              leading: Icon(
                isGranted
                    ? CupertinoIcons.checkmark_shield_fill
                    : CupertinoIcons.exclamationmark_triangle_fill,
                color: isGranted
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemOrange,
              ),
              title: Text(
                isGranted ? 'Storage Active' : 'Storage Inactive',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context),
                ),
              ),
              subtitle: Text(
                isGranted
                    ? 'Auto backups enabled'
                    : 'Tap to enable persistence',
                style: TextStyle(
                  color: _getTextColor(context).withOpacity(0.7),
                ),
              ),
              trailing: !isGranted
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Enable'),
                      onPressed: () async {
                        await _backupService.requestStoragePermission();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(isDark ? 0.3 : 0.4),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.question_circle_fill,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                tr('help_center'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr('help_text'),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showHelpDetail(),
              child: Text(
                'Open Help Center',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDetail() {
    Haptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
    );
  }

  void _showDevOptions() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Developer Options'),
        content: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable:
                    PerformanceService().isFpsOverlayEnabledNotifier,
                builder: (context, enabled, _) => SwitchListTile.adaptive(
                  title: const Text(
                    'FPS Monitor',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: enabled,
                  onChanged: (v) => PerformanceService().toggleFpsOverlay(v),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable:
                    PerformanceService().isHighRefreshEnabledNotifier,
                builder: (context, enabled, _) => SwitchListTile.adaptive(
                  title: const Text(
                    'ProMotion (120Hz)',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: enabled,
                  onChanged: (v) => PerformanceService().toggleHighRefresh(v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
