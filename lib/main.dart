import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vownote/theme/app_theme.dart';
import 'package:vownote/services/theme_service.dart';
import 'package:vownote/ui/home_screen.dart';
import 'package:vownote/services/notification_service.dart';

// Global access to theme service
final ThemeService themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(const VowNoteApp());
}

class VowNoteApp extends StatelessWidget {
  const VowNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'VowNote',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
