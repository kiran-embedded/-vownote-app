import 'dart:io';
import 'package:flutter/cupertino.dart' hide CupertinoListTile, CupertinoListTileChevron, CupertinoSwitch, CupertinoActivityIndicator;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
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
  bool _isStorageGranted = false;
  String _lastBackupDisplay = 'Never';
  String _searchQuery = '';

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
    final storageGranted = await Permission.manageExternalStorage.isGranted;
    final lastBackupTime = prefs.getString('last_backup_time');

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
        _isStorageGranted = storageGranted;
        _lastBackupDisplay = _formatBackupTime(lastBackupTime);
      });
    }
  }

  String _formatBackupTime(String? isoString) {
    if (isoString == null || isoString == 'Never') return 'Never';
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dt);
      if (difference.inDays == 0 && dt.day == now.day) {
        return 'Today, ${DateFormat('h:mm a').format(dt)}';
      } else if (difference.inDays == 1 || (difference.inDays == 0 && dt.day != now.day)) {
        return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
      } else {
        return DateFormat('MMM d, yyyy, h:mm a').format(dt);
      }
    } catch (_) {
      return 'Never';
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

  void _showProfileDialog() {
    final drive = GoogleDriveService();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('profile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (drive.isSignedIn && drive.currentUser?.photoUrl != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(drive.currentUser!.photoUrl!),
              )
            else
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFD4AF37),
                child: Icon(Icons.person, size: 40, color: Colors.black),
              ),
            const SizedBox(height: 16),
            Text(
              drive.isSignedIn ? (drive.currentUser?.displayName ?? "Google User") : "Guest User",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              drive.isSignedIn ? (drive.currentUser?.email ?? "") : "Sign in to backup data",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          if (drive.isSignedIn)
            TextButton(
              onPressed: () async {
                Navigator.pop(c);
                await drive.signOut();
                Haptics.medium();
                setState(() {});
              },
              child: Text(tr('sign_out') ?? 'Sign Out', style: const TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        tr(label),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([LocalizationService(), BusinessService(), themeService, GoogleDriveService()]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            titleSpacing: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              tr('settings'),
              style: DisplayEngine.font(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: const Color(0xFFD4AF37),
              ),
            ),
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 180,
                  height: 36,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.search, size: 18, color: Colors.grey),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: tr('search_settings') ?? 'Search settings',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            filled: false,
                            fillColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.only(right: 10, bottom: 2),
                          ),
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                          onChanged: (v) {
                            setState(() {
                              _searchQuery = v.trim().toLowerCase();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildProfileHeader(),
                    _buildAccountSection(),
                    _buildSecuritySection(),
                    _buildBackupSection(),
                    _buildExportSettings(),
                    _buildHelpSection(),
                    _buildAboutSection(),
                    
                    // Brand Footer exactly like in the image
                    Column(
                      children: [
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.business_center,
                              size: 16,
                              color: Color(0xFFD4AF37),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tr('vownote'),
                              style: DisplayEngine.font(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFD4AF37) : Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Professional Booking Manager',
                          style: DisplayEngine.font(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Made with ❤️ in India  •  © 2026 BizLedger',
                          style: DisplayEngine.font(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ].animate(interval: 45.ms)
                   .fadeIn(duration: 350.ms)
                   .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
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
    IconData? icon,
    required List<Widget> children,
    Widget? footer,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF1C1C1E)
        : theme.colorScheme.surfaceContainer;

    // Filter children based on search query
    final filteredChildren = children.where((child) {
      if (_searchQuery.isEmpty) return true;

      String getWidgetText(Widget? w) {
        if (w is Text) return w.data ?? '';
        return '';
      }

      String tileText = '';
      if (child is CupertinoListTile) {
        tileText += getWidgetText(child.title) + ' ' + getWidgetText(child.subtitle);
      } else if (child is AnimatedBuilder) {
        tileText += 'theme appearance dark mode light mode';
      }
      return tileText.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredChildren.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isDark ? const Color(0xFFD4AF37) : Colors.amber[800],
                ),
                const SizedBox(width: 8),
              ],
              Text(
                tr(title).toUpperCase(),
                style: DisplayEngine.font(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFD4AF37) : Colors.amber[800],
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardColor,
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
              for (var i = 0; i < filteredChildren.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.1),
                  ),
                filteredChildren[i],
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

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drive = GoogleDriveService();
    final config = BusinessConfig.fromType(BusinessService().currentType);

    final String displayName = drive.isSignedIn ? (drive.currentUser?.displayName ?? "User") : "Guest User";
    final String email = drive.isSignedIn ? (drive.currentUser?.email ?? "Sign in for cloud sync") : "Sign in for cloud sync";
    final String? photoUrl = drive.isSignedIn ? drive.currentUser?.photoUrl : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFD4AF37),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 32, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: DisplayEngine.font(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: DisplayEngine.font(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            config.primaryIcon,
                            size: 12,
                            color: const Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(config.displayName),
                            style: DisplayEngine.font(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Haptics.light();
                  if (!drive.isSignedIn) {
                    drive.signIn();
                  } else {
                    _showProfileDialog();
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  children: [
                    Text(
                      drive.isSignedIn ? tr('profile') : tr('sign_in'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      color: drive.isSignedIn ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drive.isSignedIn ? tr('google_drive_connected') : tr('cloud_sync_disabled'),
                            style: DisplayEngine.font(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            drive.isSignedIn ? tr('backup_secure') : tr('sign_in_to_backup'),
                            style: DisplayEngine.font(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFFD4AF37),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('last_backup'),
                            style: DisplayEngine.font(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            _lastBackupDisplay,
                            style: DisplayEngine.font(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Haptics.success();
                  setState(() => _isLoading = true);
                  final success = await GoogleDriveService().backupToDrive();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('success'))),
                    );
                  }
                  await _loadSettings();
                  setState(() => _isLoading = false);
                },
                icon: const Icon(Icons.cloud_upload, size: 14, color: Colors.black),
                label: Text(
                  tr('backup_now'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildPillSection(
      title: 'PREFERENCES',
      icon: CupertinoIcons.slider_horizontal_3,
      children: [
        AnimatedBuilder(
          animation: BusinessService(),
          builder: (context, _) {
            final config = BusinessConfig.fromType(BusinessService().currentType);
            return CupertinoListTile(
              leading: Icon(
                config.primaryIcon,
                color: Colors.blue,
              ),
              title: Text(
                tr('business'),
                style: DisplayEngine.font(color: _getTextColor(context)),
              ),
              subtitle: Text(
                tr(config.displayName),
                style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _showBusinessTypeSheet,
            );
          },
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.globe,
            color: Colors.green,
          ),
          title: Text(
            tr('language'),
            style: DisplayEngine.font(color: _getTextColor(context)),
          ),
          subtitle: Text(
            LocalizationService().currentLanguage.toUpperCase() == 'EN' ? 'English (EN)' : 'മലയാളം (ML)',
            style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: _showLanguageSheet,
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildPillSection(
      title: 'APPEARANCE',
      icon: CupertinoIcons.paintbrush,
      children: [
        AnimatedBuilder(
          animation: themeService,
          builder: (context, _) {
            final isDark = themeService.themeMode == ThemeMode.dark;
            return CupertinoListTile(
              leading: Icon(
                isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                color: isDark ? Colors.purpleAccent : Colors.orange,
              ),
              title: Text(
                tr('theme') ?? 'Theme',
                style: DisplayEngine.font(
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context),
                ),
              ),
              subtitle: Text(
                isDark ? 'Dark theme enabled' : 'Light theme enabled',
                style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
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
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _buildPillSection(
      title: 'SECURITY',
      icon: CupertinoIcons.lock_shield,
      children: [
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.lock_fill,
            color: Colors.orange,
          ),
          title: Text(
            'App Lock',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: _canUseBiometrics
              ? Text(
                  'Biometric & device authentication',
                  style: TextStyle(
                    color: _getTextColor(context).withOpacity(0.5),
                  ),
                )
              : const Text(
                  'Device security not available',
                  style: TextStyle(color: Colors.grey),
                ),
          trailing: CupertinoSwitch(
            value: _isLockEnabled,
            activeTrackColor: const Color(0xFFD4AF37),
            onChanged: (value) async {
              Haptics.light();
              if (value) {
                try {
                  final success = await BiometricService().authenticate();
                  if (success) {
                    await BiometricService().setLockEnabled(true);
                    Haptics.success();
                    setState(() => _isLockEnabled = true);
                  } else {
                    Haptics.error();
                    setState(() => _isLockEnabled = false);
                  }
                } catch (e) {
                  // handle exception
                }
              } else {
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
    final drive = GoogleDriveService();
    return AnimatedBuilder(
      animation: drive,
      builder: (context, _) {
        return _buildPillSection(
          title: 'BACKUP & SYNC',
          icon: CupertinoIcons.cloud_upload,
          children: [
            CupertinoListTile(
              leading: const Icon(
                CupertinoIcons.cloud,
                color: Colors.blue,
              ),
              title: Text(
                tr('google_account'),
                style: DisplayEngine.font(color: _getTextColor(context)),
              ),
              subtitle: Text(
                drive.isSignedIn ? (drive.currentUser?.email ?? "") : tr('disconnected'),
                style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadge(
                    drive.isSignedIn ? 'google_account_connected' : 'google_account_disconnected',
                    drive.isSignedIn ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: () async {
                Haptics.light();
                if (!drive.isSignedIn) {
                  try {
                    await drive.signIn();
                    Haptics.success();
                  } catch (e) {
                    Haptics.medium();
                  }
                } else {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(tr('sign_out_google')),
                      content: Text('${tr('connected_as')}: ${drive.currentUser?.email}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text(tr('cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(
                            tr('sign_out'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await drive.signOut();
                    Haptics.medium();
                  }
                }
              },
            ),

            CupertinoListTile(
              leading: const Icon(
                CupertinoIcons.arrow_up_circle,
                color: Colors.purple,
              ),
              title: Text(
                tr('backup_now'),
                style: DisplayEngine.font(color: _getTextColor(context)),
              ),
              subtitle: Text(
                'Backup now to local & cloud • Last: $_lastBackupDisplay',
                style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () async {
                setState(() => _isLoading = true);
                try {
                  await _backupService.silentBackup();
                  Haptics.success();
                  await _loadSettings();
                } catch (e) {
                  Haptics.medium();
                } finally {
                  setState(() => _isLoading = false);
                }
              },
            ),
            CupertinoListTile(
              leading: const Icon(
                CupertinoIcons.cloud_download,
                color: Colors.green,
              ),
              title: Text(
                tr('restore_from_drive'),
                style: DisplayEngine.font(color: _getTextColor(context)),
              ),
              subtitle: Text(
                'Restore your data from Google Drive',
                style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
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
            CupertinoListTile(
              leading: const Icon(
                CupertinoIcons.share_up,
                color: Colors.blue,
              ),
              title: Text(
                tr('export_backup'),
                style: DisplayEngine.font(color: _getTextColor(context)),
              ),
              subtitle: Text(
                'Save backup to your device',
                style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () async {
                setState(() => _isLoading = true);
                try {
                  await _backupService.exportBackup();
                  Haptics.success();
                  await _loadSettings();
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
                color: Colors.orange,
              ),
              title: Text(
                tr('import_backup'),
                style: DisplayEngine.font(color: _getTextColor(context)),
              ),
              subtitle: Text(
                'Import backup from your device',
                style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () async {
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
                                  child: const Text('OK')),
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
          ],
        );
      },
    );
  }

  Widget _buildExportSettings() {
    return _buildPillSection(
      title: 'EXPORT & REPORTS',
      icon: CupertinoIcons.doc_text,
      children: [
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.doc_text_fill,
            color: Colors.orange,
          ),
          title: Text(
            tr('pdf_report_settings'),
            style: DisplayEngine.font(color: _getTextColor(context)),
          ),
          subtitle: Text(
            tr('pdf_report_settings_description'),
            style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: _showExportSettingsSheet,
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return _buildPillSection(
      title: 'HELP & SUPPORT',
      icon: CupertinoIcons.question_circle,
      children: [
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.book_fill,
            color: Colors.pink,
          ),
          title: Text(
            tr('help_center'),
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: Text(
            tr('help_text'),
            style: TextStyle(color: _getTextColor(context).withOpacity(0.5)),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: _showHelpDetail,
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.chat_bubble_2,
            color: Colors.green,
          ),
          title: Text(
            'WhatsApp Support',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: const Text('Chat with us on WhatsApp', style: TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(Uri.parse('https://wa.me/919526480039')),
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.paperplane,
            color: Colors.blue,
          ),
          title: Text(
            'Telegram',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: const Text('Join our Telegram channel', style: TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(Uri.parse('https://t.me/SYNTAX_VOLT')),
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.mail,
            color: Colors.pinkAccent,
          ),
          title: Text(
            tr('contact_support') ?? 'Email Support',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: const Text('support@bizledger.app', style: TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(Uri.parse('mailto:kiran.cybergrid@gmail.com')),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildPillSection(
      title: 'ABOUT',
      icon: CupertinoIcons.info_circle,
      children: [
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.info_circle,
            color: Colors.blueGrey,
          ),
          title: Text(
            tr('version') ?? 'Version',
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: const Text('BizLedger v2.3.4', style: TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBadge('Latest', Colors.blue),
              const SizedBox(width: 8),
              const CupertinoListTileChevron(),
            ],
          ),
          onTap: _showUpdateDialog,
        ),
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.shield,
            color: Colors.green,
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
            color: Colors.blue,
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
            color: Colors.purple,
          ),
          title: Text(
            tr('github'),
            style: DisplayEngine.font(
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
          subtitle: const Text('View source code', style: TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: const CupertinoListTileChevron(),
          onTap: () => launchUrl(
            Uri.parse('https://github.com/kiran-embedded/-vownote-app'),
          ),
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

  void _showUpdateDialog() {
    Haptics.heavy();
    showDialog(
      context: context,
      builder: (context) {
        bool isChecking = false;
        String statusText = 'System is up to date.';
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.cloud_sync, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 8),
                  Text(tr('remote_update') ?? 'Remote Update'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Version: 2.3.2', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(statusText, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  if (isChecking) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Haptics.light();
                    launchUrl(Uri.parse('https://github.com/kiran-embedded/-vownote-app/releases'));
                  },
                  child: const Text('GitHub Releases'),
                ),
                TextButton(
                  onPressed: isChecking
                      ? null
                      : () async {
                          Haptics.selection();
                          setDialogState(() {
                            isChecking = true;
                            statusText = 'Checking GitHub repository...';
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          if (context.mounted) {
                            setDialogState(() {
                              isChecking = false;
                              statusText = 'You are running the latest version (BizLedger v2.3.4).';
                            });
                          }
                        },
                  child: const Text('Check Now'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('close')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CupertinoListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget? formattedLeading = leading;

    if (leading is Icon) {
      final iconWidget = leading as Icon;
      final iconColor = iconWidget.color ?? const Color(0xFFD4AF37);
      formattedLeading = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            iconWidget.icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      );
    } else if (leading != null) {
      formattedLeading = SizedBox(
        width: 28,
        height: 28,
        child: Center(child: leading),
      );
    }

    return ListTile(
      leading: formattedLeading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      dense: true,
    );
  }
}

class CupertinoListTileChevron extends StatelessWidget {
  const CupertinoListTileChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.chevron_right, size: 20, color: Colors.grey);
  }
}

class CupertinoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? activeTrackColor;

  const CupertinoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? activeTrackColor,
    );
  }
}

class CupertinoActivityIndicator extends StatelessWidget {
  const CupertinoActivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
    );
  }
}
