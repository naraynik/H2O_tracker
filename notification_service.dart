import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Initialize Timezone properly
    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    // Setup Android initialization settings using the default app icon
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Can add logic here if user taps the notification
      },
    );
  }

  static Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleDailyReminders() async {
    // Cancel any existing notifications first so we don't accidentally duplicate
    await _notificationsPlugin.cancelAll();

    // Requested notification intervals
    final List<Map<String, int>> times = [
      {'hour':  8, 'minute': 0},   // 8:00 AM
      {'hour': 10, 'minute': 30},  // 10:30 AM
      {'hour': 13, 'minute': 0},   // 1:00 PM
      {'hour': 15, 'minute': 30},  // 3:30 PM
      {'hour': 18, 'minute': 0},   // 6:00 PM
      {'hour': 20, 'minute': 30},  // 8:30 PM
    ];

    int id = 0;
    for (var time in times) {
      await _scheduleDailyNotification(
        id: id++,
        hour: time['hour']!,
        minute: time['minute']!,
      );
    }
  }

  static Future<void> _scheduleDailyNotification({required int id, required int hour, required int minute}) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      'Time to Hydrate! 💧',
      'Jal Lijiye', // Requested body text
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'h2o_tracker_daily',
          'Hydration Reminders',
          channelDescription: 'Daily scheduled reminders to drink water',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00E5FF),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // If the time has already passed today, schedule it for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
