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

  Future<void> _scheduleZoned(int id, String title, String body, DateTime scheduledDate) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
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
        androidScheduleMode: fln.AndroidScheduleMode.exact,
      );
    } catch (e) {
      // Fallback to inexact if exact fails (prevents crash/error)
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          const fln.NotificationDetails(
            android: fln.AndroidNotificationDetails(
              'wedding_reminders',
              'Wedding Reminders',
              importance: fln.Importance.defaultImportance,
              priority: fln.Priority.defaultPriority,
            ),
            iOS: fln.DarwinNotificationDetails(),
          ),
          androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  Future<void> scheduleBookingReminders(Booking booking) async {
    final names = booking.groomName.isNotEmpty
        ? '${booking.brideName} & ${booking.groomName}'
        : booking.brideName;

    for (var date in booking.eventDates) {
      // 1. Day of event reminder at 9:00 AM
      final scheduledDate = DateTime(date.year, date.month, date.day, 9, 0);
      if (!scheduledDate.isBefore(DateTime.now())) {
        final notificationId = (booking.id.hashCode + date.hashCode).abs();
        await _scheduleZoned(
          notificationId,
          'Wedding Today: $names',
          'Reminder regarding wedding event today at ${booking.address}',
          scheduledDate,
        );
      }

      // 2. 1 Day before event reminder at 9:00 AM
      final dayBeforeDate = scheduledDate.subtract(const Duration(days: 1));
      if (!dayBeforeDate.isBefore(DateTime.now())) {
        final notificationIdBefore = (booking.id.hashCode + date.hashCode + 1).abs();
        await _scheduleZoned(
          notificationIdBefore,
          'Upcoming Wedding Tomorrow: $names',
          'Wedding event is tomorrow at ${booking.address}',
          dayBeforeDate,
        );
      }
    }
  }

  Future<void> cancelNotifications(Booking booking) async {
    for (var date in booking.eventDates) {
      final notificationId = (booking.id.hashCode + date.hashCode).abs();
      final notificationIdBefore = (booking.id.hashCode + date.hashCode + 1).abs();
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      await flutterLocalNotificationsPlugin.cancel(notificationIdBefore);
    }
  }
}
