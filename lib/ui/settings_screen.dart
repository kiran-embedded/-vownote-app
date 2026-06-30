import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:vownote/services/google_drive_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vownote/utils/display_engine.dart';
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
  void _showBusinessTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: AnimatedBuilder(
            animation: BusinessService(),
            builder: (context, _) {
              final currentType = BusinessService().currentType;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('select_business_type'),
                    style: DisplayEngine.font(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...BusinessType.values.map((type) {
                    final config = BusinessConfig.fromType(type);

                    Widget iconWidget = Icon(
                      config.primaryIcon,
                      size: 24,
                      color: config.accentColor,
                    );

                    switch (type) {
                      case BusinessType.wedding:
                        iconWidget = iconWidget
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .scale(
                              duration: 600.ms,
                              begin: const Offset(1, 1),
                              end: const Offset(1.2, 1.2),
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .scale(
                              duration: 600.ms,
                              begin: const Offset(1.2, 1.2),
                              end: const Offset(1, 1),
                              curve: Curves.easeInOut,
                            );
                        break;
                      case BusinessType.photography:
                        iconWidget = iconWidget
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .shimmer(duration: 1000.ms, color: Colors.white54)
                            .shake(
                              hz: 2,
                              curve: Curves.easeInOut,
                              duration: 500.ms,
                            )
                            .then(delay: 500.ms);
                        break;
                      case BusinessType.catering:
                        iconWidget = iconWidget
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .slideY(
                              begin: 0,
                              end: -0.3,
                              duration: 400.ms,
                              curve: Curves.easeOut,
                            )
                            .then()
                            .slideY(
                              begin: -0.3,
                              end: 0,
                              duration: 400.ms,
                              curve: Curves.bounceOut,
                            )
                            .then(delay: 800.ms);
                        break;
                      case BusinessType.eventPlanning:
                        iconWidget = iconWidget
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .rotate(
                              begin: -0.1,
                              end: 0.1,
                              duration: 300.ms,
                              curve: Curves.easeInOut,
                            )
                            .then(delay: 500.ms);
                        break;
                      case BusinessType.general:
                        iconWidget = iconWidget
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(
                              duration: 2000.ms,
                              color: config.accentColor.withOpacity(0.5),
                            );
                        break;
                    }

                    return CupertinoListTile(
                      leading: iconWidget,
                      title: Text(
                        tr(config.displayName),
                        style: DisplayEngine.font(color: _getTextColor(context)),
                      ),
                      trailing: currentType == type
                          ? const Icon(
                              CupertinoIcons.check_mark,
                              color: Colors.blue,
                            )
                          : null,
                      onTap: () async {
                        Haptics.medium();
                        await BusinessService().setBusinessType(type);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showLanguageSheet() {
    final List<Map<String, String>> langs = [
      {'code': 'en', 'label': '🇺🇸 English (United States)'},
      {'code': 'ml', 'label': '🇮🇳 മലയാളം'},
      {'code': 'hi', 'label': '🇮🇳 हिन्दी'},
      {'code': 'ta', 'label': '🇮🇳 தமிழ்'},
      {'code': 'es', 'label': '🇪🇸 Español'},
      {'code': 'fr', 'label': '🇫🇷 Français'},
      {'code': 'ar', 'label': '🇸🇦 العربية'},
      {'code': 'de', 'label': '🇩🇪 Deutsch'},
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('language'),
                style: DisplayEngine.font(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: langs.length,
                  itemBuilder: (context, index) {
                    final lang = langs[index];
                    final isSelected =
                        LocalizationService().currentLanguage == lang['code'];
                    return CupertinoListTile(
                      title: Text(
                        lang['label']!,
                        style: DisplayEngine.font(color: _getTextColor(context)),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              CupertinoIcons.check_mark,
                              color: Colors.blue,
                            )
                          : null,
                      onTap: () async {
                        Haptics.selection();
                        await LocalizationService().setLanguage(lang['code']!);
                        if (context.mounted) {
                          Navigator.pop(context);
                          // Force rebuild of settings screen to reflect language subtitle change immediately
                          // Note: UI updates anyway because of AnimatedBuilder on root, but setState forces local rebuild
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showExportSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('export_settings'),
                      style: DisplayEngine.font(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.book,
                        color: Colors.purple,
                        size: 24,
                      ),
                      title: Text(
                        tr('show_diary'),
                        style: DisplayEngine.font(color: _getTextColor(context)),
                      ),
                      trailing: CupertinoSwitch(
                        value: _showDiary,
                        onChanged: (v) {
                          Haptics.light();
                          _updateSetting('show_diary_in_export', v);
                          setStateSheet(() => _showDiary = v);
                        },
                        activeColor: const Color(0xFFD4AF37),
                      ),
                    ),
                    CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.person_2,
                        color: Colors.blue,
                        size: 24,
                      ),
                      title: Text(
                        tr('show_names'),
                        style: DisplayEngine.font(color: _getTextColor(context)),
                      ),
                      trailing: CupertinoSwitch(
                        value: _showBrideGroom,
                        onChanged: (v) {
                          Haptics.light();
                          _updateSetting('show_names_in_export', v);
                          setStateSheet(() => _showBrideGroom = v);
                        },
                        activeColor: const Color(0xFFD4AF37),
                      ),
                    ),
                    CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.phone,
                        color: Colors.orange,
                        size: 24,
                      ),
                      title: Text(
                        tr('show_phone'),
                        style: DisplayEngine.font(color: _getTextColor(context)),
                      ),
                      trailing: CupertinoSwitch(
                        value: _showPhone,
                        onChanged: (v) {
                          Haptics.light();
                          _updateSetting('show_phone_in_export', v);
                          setStateSheet(() => _showPhone = v);
                        },
                        activeColor: const Color(0xFFD4AF37),
                      ),
                    ),
                    CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.location,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                      title: Text(
                        tr('show_address'),
                        style: DisplayEngine.font(color: _getTextColor(context)),
                      ),
                      trailing: CupertinoSwitch(
                        value: _showAddress,
                        onChanged: (v) {
                          Haptics.light();
                          _updateSetting('show_address_in_export', v);
                          setStateSheet(() => _showAddress = v);
                        },
                        activeColor: const Color(0xFFD4AF37),
                      ),
                    ),
                    CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.money_dollar,
                        color: Colors.green,
                        size: 24,
                      ),
                      title: Text(
                        tr('money_in_pdf'),
                        style: DisplayEngine.font(color: _getTextColor(context)),
                      ),
                      trailing: CupertinoSwitch(
                        value: _showMoneyInPdf,
                        onChanged: (v) {
                          Haptics.light();
                          _updateSetting('show_money_in_pdf', v);
                          setStateSheet(() => _showMoneyInPdf = v);
                        },
                        activeColor: const Color(0xFFD4AF37),
                      ),
                    ),
                    CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.camera,
                        color: const Color(0xFFD4AF37),
                        size: 24,
                      ),
                      title: Text(
                        tr('screenshot_4k'),
                        style: DisplayEngine.font(color: _getTextColor(context)),
                      ),
                      trailing: CupertinoSwitch(
                        value: _use4K,
                        onChanged: (v) {
                          Haptics.light();
                          _updateSetting('use_4k_screenshots', v);
                          setStateSheet(() => _use4K = v);
                        },
                        activeColor: const Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalizationService(),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: ShimmerText(
              tr('settings'),
              style: DisplayEngine.font(fontWeight: FontWeight.w600),
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
                            _buildAppearanceSection(),
                            _buildSecuritySection(),
                            _buildExportSettings(),
                            _buildBackupSection(),
                            _buildHelpSection(),
                            _buildAboutSection(),
                            const SizedBox(height: 40),
                          ]
                          .animate(interval: 50.ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
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
      },
    );
  }

  // Helper for dynamic text color logic
  Color _getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black;
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
            tr(title),
            style: DisplayEngine.font(
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
        title: Text('${tr('change_to')} ${tr(config.type.name)}?'),
        content: Text(
          'This will update the app to use ${tr(config.displayName).toLowerCase()} terminology and settings.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('change')),
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
            content: Text('${tr('business_changed')} ${tr(config.type.name)}'),
            backgroundColor: config.accentColor,
          ),
        );
      }
    }
  }

  Widget _buildBusinessTypeSection() {
    return _buildPillSection(
      title: 'BUSINESS',
      children: [
        AnimatedBuilder(
          animation: BusinessService(),
          builder: (context, _) {
            final config = BusinessConfig.fromType(
              BusinessService().currentType,
            );
            return CupertinoListTile(
              leading: Icon(
                config.primaryIcon,
                color: CupertinoColors.activeBlue,
              ),
              title: Text(
                tr('business_type'),
                style: DisplayEngine.font(color: _getTextColor(context)),
              ),
              subtitle: Text(
                tr(config.displayName),
                style: TextStyle(
                  color: _getTextColor(context).withOpacity(0.5),
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _showBusinessTypeSheet,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildPillSection(
      title: 'APPEARANCE',
      children: [
        AnimatedBuilder(
          animation: themeService,
          builder: (context, _) {
            final isDark = themeService.themeMode == ThemeMode.dark;
            return CupertinoListTile(
              leading: Icon(
                isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                color: isDark ? Colors.purpleAccent : Colors.orange,
              ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
              title: Text(
                tr('dark_mode'),
                style: DisplayEngine.font(
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
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.globe,
            color: CupertinoColors.activeGreen,
          ),
          title: Text(
            tr('language'),
            style: DisplayEngine.font(color: _getTextColor(context)),
          ),
          subtitle: Text(
            LocalizationService().currentLanguage.toUpperCase(),
            style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: _showLanguageSheet,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildPillSection(
      title: 'ABOUT',
      children: [
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.systemGrey,
          ),
          title: Text(
            '${tr('version')} 2.3.2',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          onTap: () {
            Haptics.heavy();
            _showDevOptions();
          },
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.shield,
            color: CupertinoColors.activeGreen,
          ),
          title: Text(
            tr('privacy_policy'),
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(
            Uri.parse(
              'https://github.com/kiran-embedded/-vownote-app/blob/main/README.md',
            ),
          ),
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.doc_text,
            color: CupertinoColors.activeBlue,
          ),
          title: Text(
            tr('licenses'),
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => showLicensePage(context: context),
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.chevron_left_slash_chevron_right,
            color: CupertinoColors.systemPurple,
          ),
          title: Text(
            tr('github'),
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(
            Uri.parse('https://github.com/kiran-embedded/-vownote-app'),
          ),
        ),
      ],
    );
  }

  Widget _buildExportSettings() {
    return _buildPillSection(
      title: 'EXPORT',
      children: [
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.doc_text_fill,
            color: CupertinoColors.systemOrange,
          ),
          title: Text(
            tr('export_settings'),
            style: DisplayEngine.font(color: _getTextColor(context)),
          ),
          subtitle: Text(
            tr('manage_pdf_layout'),
            style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: _showExportSettingsSheet,
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
        style: DisplayEngine.font(
          fontWeight: FontWeight.w500,
          color: _getTextColor(context),
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: (v) {
          Haptics.light();
          onChanged(v);
        },
        activeColor: const Color(0xFFD4AF37),
      ),
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
            style: DisplayEngine.font(
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
    return FutureBuilder<bool>(
      future: Permission.manageExternalStorage.isGranted,
      builder: (context, snapshot) {
        final isGranted = snapshot.data ?? false;

        return _buildPillSection(
          title: 'BACKUP & SYNC',
          children: [
            CupertinoListTile(
              leading: const Icon(
                CupertinoIcons.share_up,
                color: CupertinoColors.activeBlue,
              ),
              title: Text(
                tr('export_backup'),
                style: DisplayEngine.font(
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context),
                ),
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
                tr('import_backup'),
                style: DisplayEngine.font(
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context),
                ),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(tr('restore_backup')),
                    content: Text(
                      tr('import_backup_warning'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text(tr('cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: Text(tr('import')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  setState(() => _isLoading = true);
                  try {
                    final status = await _backupService.importBackup();
                    if (status == 1) {
                      Haptics.success();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => AlertDialog(
                            title: Text(tr('success')),
                            content: Text(tr('restore_success')),
                            actions: [
                              TextButton(
                                onPressed: () => exit(0),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    } else {
                      Haptics.light();
                    }
                  } catch (e) {
                    Haptics.medium();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Import failed: $e')),
                      );
                    }
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }
              },
            ),
            CupertinoListTile(
              leading: Icon(
                isGranted
                    ? CupertinoIcons.cloud_upload_fill
                    : CupertinoIcons.exclamationmark_triangle_fill,
                color: isGranted
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemOrange,
              ),
              title: Text(
                tr('auto_backup'),
                style: DisplayEngine.font(
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context),
                ),
              ),
              trailing: isGranted
                  ? const Icon(
                      CupertinoIcons.check_mark,
                      color: CupertinoColors.activeGreen,
                    )
                  : CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(tr('enable')),
                      onPressed: () async {
                        await _backupService.requestStoragePermission();
                        setState(() {});
                      },
                    ),
            ),
            const Divider(height: 1, indent: 50),
            AnimatedBuilder(
              animation: GoogleDriveService(),
              builder: (context, _) {
                final drive = GoogleDriveService();
                if (!drive.isSignedIn) {
                  return CupertinoListTile(
                    leading: const Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          CupertinoIcons.cloud,
                          color: CupertinoColors.systemGrey,
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            size: 12,
                            color: CupertinoColors.systemOrange,
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      tr('sign_in_google'),
                      style: DisplayEngine.font(
                        fontWeight: FontWeight.w500,
                        color: _getTextColor(context),
                      ),
                    ),
                    trailing: drive.isLoading
                        ? const CupertinoActivityIndicator()
                        : const CupertinoListTileChevron(),
                    onTap: drive.isLoading
                        ? null
                        : () async {
                            try {
                              await drive.signIn();
                              Haptics.success();
                            } catch (e) {
                              Haptics.medium();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Sign in failed: $e')),
                                );
                              }
                            }
                          },
                  );
                }

                return Column(
                  children: [
                    CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.person_crop_circle_fill,
                        color: CupertinoColors.activeBlue,
                      ),
                      title: Text(
                        '${tr('connected_as')}: ${drive.currentUser?.email ?? ""}',
                        style: DisplayEngine.font(
                          fontSize: 12,
                          color: _getTextColor(context),
                        ),
                      ),
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: drive.isLoading
                            ? null
                            : () async {
                                await drive.signOut();
                                Haptics.light();
                              },
                        child: Text(
                          tr('sign_out'),
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 50),
                    CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.cloud_upload,
                        color: CupertinoColors.activeBlue,
                      ),
                      title: Text(
                        tr('backup_to_drive'),
                        style: DisplayEngine.font(
                          fontWeight: FontWeight.w500,
                          color: _getTextColor(context),
                        ),
                      ),
                      trailing: drive.isBackingUp
                          ? const CupertinoActivityIndicator()
                          : const CupertinoListTileChevron(),
                      onTap: drive.isBackingUp
                          ? null
                          : () async {
                              final success = await drive.backupToDrive();
                              if (context.mounted) {
                                if (success) {
                                  Haptics.success();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(tr('backup_success'))),
                                  );
                                } else {
                                  Haptics.medium();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(tr('error_backup'))),
                                  );
                                }
                              }
                            },
                    ),
                    const Divider(height: 1, indent: 50),
                    CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.cloud_download,
                        color: CupertinoColors.activeGreen,
                      ),
                      title: Text(
                        tr('restore_from_drive'),
                        style: DisplayEngine.font(
                          fontWeight: FontWeight.w500,
                          color: _getTextColor(context),
                        ),
                      ),
                      trailing: drive.isRestoring
                          ? const CupertinoActivityIndicator()
                          : const CupertinoListTileChevron(),
                      onTap: drive.isRestoring
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: Text(tr('restore_backup')),
                                  content: Text(tr('import_backup_warning')),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: Text(tr('cancel')),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: Text(tr('import')),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final success = await drive.restoreFromDrive();
                                if (context.mounted) {
                                  if (success) {
                                    Haptics.success();
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (c) => AlertDialog(
                                        title: Text(tr('success')),
                                        content: Text(tr('restore_success')),
                                        actions: [
                                          TextButton(
                                            onPressed: () => exit(0),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    Haptics.medium();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(tr('error_restore'))),
                                    );
                                  }
                                }
                              }
                            },
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpSection() {
    return _buildPillSection(
      title: 'HELP',
      children: [
        CupertinoListTile(
          leading: const Text('❓', style: TextStyle(fontSize: 20)),
          title: Text(
            tr('help_center'),
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: Text(
            tr('help_text'),
            style: TextStyle(color: _getTextColor(context).withOpacity(0.7)),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: _showHelpDetail,
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.chat_bubble_2,
            color: CupertinoColors.activeGreen,
          ),
          title: Text(
            'WhatsApp',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(Uri.parse('https://wa.me/919526480039')),
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.paperplane,
            color: CupertinoColors.activeBlue,
          ),
          title: Text(
            'Telegram',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(Uri.parse('https://t.me/SYNTAX_VOLT')),
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.mail,
            color: CupertinoColors.systemRed,
          ),
          title: Text(
            tr('contact_support') ?? 'Contact Support',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(Uri.parse('mailto:kiran.cybergrid@gmail.com')),
        ),
      ],
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
        title: Text(tr('developer_options')),
        content: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable:
                    PerformanceService().isFpsOverlayEnabledNotifier,
                builder: (context, enabled, _) => SwitchListTile.adaptive(
                  title: Text(
                    tr('fps_monitor'),
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
                  title: Text(
                    tr('promotion_120hz'),
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
            child: Text(tr('close')),
          ),
        ],
      ),
    );
  }
}
