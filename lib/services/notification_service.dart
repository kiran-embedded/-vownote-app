import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:vownote/models/booking.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization (requires permission request later)
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (fln.NotificationResponse response) async {
            // Handle notification tap
          },
    );
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleBookingReminders(Booking booking) async {
    for (var date in booking.eventDates) {
      // Schedule for 9:00 AM on the wedding day
      final scheduledDate = DateTime(date.year, date.month, date.day, 9, 0);

      if (scheduledDate.isBefore(DateTime.now())) continue;

      // Unique ID based on booking ID hash + date hash
      final notificationId = (booking.id.hashCode + date.hashCode).abs();

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Wedding Today: ${booking.brideName}',
        'Reminder regarding wedding event today at ${booking.address}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'wedding_reminders',
            'Wedding Reminders',
            channelDescription: 'Notifications for wedding events',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelNotifications(Booking booking) async {
    for (var date in booking.eventDates) {
      final notificationId = (booking.id.hashCode + date.hashCode).abs();
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }
}
