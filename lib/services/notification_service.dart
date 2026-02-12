import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_settings.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));
  }

  Future<void> applySchedule(AppSettings settings, {bool requestPermissionIfNeeded = false}) async {
    await _plugin.cancelAll();
    if (!settings.reminderEnabled) return;

    if (requestPermissionIfNeeded) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    final now = DateTime.now();
    final wake = _todayAt(settings.wakeMinutes);
    final sleep = _todayAt(settings.sleepMinutes);
    var cursor = now.isBefore(wake) ? wake : now.add(Duration(minutes: settings.intervalMinutes));
    var id = 100;

    while (cursor.isBefore(sleep)) {
      await _plugin.schedule(
        id++,
        '💧',
        ' ',
        cursor,
        const NotificationDetails(
          android: AndroidNotificationDetails('dropglass_reminders', 'DropGlass reminders', importance: Importance.defaultImportance),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      cursor = cursor.add(Duration(minutes: settings.intervalMinutes));
    }
  }

  DateTime _todayAt(int minutes) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(minutes: minutes));
  }
}
