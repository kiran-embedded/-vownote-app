import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vownote/theme/app_theme.dart';
import 'package:vownote/services/theme_service.dart';
import 'package:vownote/ui/home_screen.dart';
import 'package:vownote/services/notification_service.dart';
import 'package:vownote/services/backup_service.dart';
import 'package:vownote/services/localization_service.dart';
import 'package:vownote/services/performance_service.dart';
import 'package:vownote/services/business_service.dart';
import 'package:vownote/ui/widgets/performance_overlay.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:vownote/ui/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Localization support
import 'package:vownote/services/biometric_service.dart'; // Added Import

// Global access to theme service
final ThemeService themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // High Refresh Rate Optimization
  try {
    await FlutterRefreshRateControl().requestHighRefreshRate();
  } catch (e) {
    debugPrint('Refresh rate control failed: $e');
  }

  await LocalizationService().init();
  await PerformanceService().init();
  await BusinessService().init(); // Initialize business service
  await Haptics.init(); // Initialize enhanced haptics

  // RAM Optimization: Limit image cache size
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      10 * 1024 * 1024; // 10MB

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Initialize Notifications
  try {
    debugPrint('Initializing NotificationService...');
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();
    debugPrint('NotificationService initialized successfully.');
  } catch (e) {
    debugPrint('Error initializing NotificationService: $e');
  }

  // Request Storage Permissions for Background Sync
  try {
    await BackupService().requestStoragePermission();
    await BackupService().silentBackup();
  } catch (e) {
    debugPrint('Error initializing Storage: $e');
  }

  runApp(const BizLedgerApp());
}

class BizLedgerApp extends StatefulWidget {
  const BizLedgerApp({super.key});

  @override
  State<BizLedgerApp> createState() => _BizLedgerAppState();
}

class _BizLedgerAppState extends State<BizLedgerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (await BiometricService().needsAuthentication()) {
        // Trigger Auth
        final authenticated = await BiometricService().authenticate();
        if (!authenticated) {
          // Minimize or exit if auth fails?
          // For now, loop or just visually block is harder without a dedicated screen.
          // Best approach: Just call authenticate() again or keep prompting.
          // But BiometricService().authenticate() handles the UI.
          // If they cancel, we might want to force closed?
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'BizLedger',
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: const Duration(
            milliseconds: 300,
          ), // Optimized from 800ms
          themeAnimationCurve: Curves.easeInOutQuart, // Snappier curve
          themeMode: themeService.themeMode,
          // Material You Dynamic Color Builder
          builder: (context, child) {
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                // Use dynamic colors if enabled and available
                final useDynamic = themeService.useDynamicColors;
                ThemeData lightTheme;
                ThemeData darkTheme;

                if (useDynamic && lightDynamic != null && darkDynamic != null) {
                  lightTheme = AppTheme.createDynamicLightTheme(lightDynamic);
                  darkTheme = AppTheme.createDynamicDarkTheme(darkDynamic);
                } else {
                  // Fallback to static themes
                  lightTheme = AppTheme.lightTheme;
                  darkTheme = AppTheme.darkTheme;
                }

                return MaterialApp(
                  title: 'BizLedger',
                  debugShowCheckedModeBanner: false,
                  themeAnimationDuration: const Duration(milliseconds: 300),
                  themeAnimationCurve: Curves.easeInOutQuart,
                  theme: lightTheme.copyWith(
                    pageTransitionsTheme: const PageTransitionsTheme(
                      builders: {
                        TargetPlatform.android:
                            CupertinoPageTransitionsBuilder(),
                        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                      },
                    ),
                  ),
                  darkTheme: darkTheme.copyWith(
                    pageTransitionsTheme: const PageTransitionsTheme(
                      builders: {
                        TargetPlatform.android:
                            CupertinoPageTransitionsBuilder(),
                        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                      },
                    ),
                  ),
                  themeMode: themeService.themeMode,
                  home: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(LocalizationService().currentLanguage),
                      child: const AuthGate(
                        child: HomeScreen(),
                      ), // Protected by AuthGate
                    ),
                  ),
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en'),
                    Locale('ml'),
                    Locale('hi'),
                    Locale('ta'),
                    Locale('es'),
                    Locale('fr'),
                    Locale('ar'),
                    Locale('de'),
                    Locale('id'),
                    Locale('pt'),
                  ],
                  builder: (context, widget) {
                    return GestureDetector(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: GlobalPerformanceOverlay(child: widget!),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
