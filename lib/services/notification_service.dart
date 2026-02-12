import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _baseNotificationId = 100;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _soundEnabled = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));
    _initialized = true;
  }

  Future<void> initialize() => init();

  Future<bool> requestPermissionsIfNeeded() async {
    final iosImplementation = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final granted = await iosImplementation?.requestPermissions(alert: true, badge: false, sound: false);
    return granted ?? true;
  }

  Future<void> rescheduleDailyWindow({
    required bool enabled,
    required TimeOfDay wake,
    required TimeOfDay sleep,
    required int intervalMinutes,
  }) async {
    await cancelAll();
    if (!enabled || intervalMinutes <= 0) return;

    final now = DateTime.now();
    var wakeDateTime = _atToday(wake, now);
    var sleepDateTime = _atToday(sleep, now);

    if (!sleepDateTime.isAfter(wakeDateTime)) {
      sleepDateTime = sleepDateTime.add(const Duration(days: 1));
    }

    if (now.isAfter(sleepDateTime)) {
      wakeDateTime = wakeDateTime.add(const Duration(days: 1));
      sleepDateTime = sleepDateTime.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'reminder',
        'Reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(presentSound: _soundEnabled),
    );

    var id = _baseNotificationId;
    var cursor = wakeDateTime;
    while (!cursor.isAfter(sleepDateTime)) {
      if (cursor.isAfter(now)) {
        await _plugin.zonedSchedule(
          id++,
          '水を飲もう',
          '',
          tz.TZDateTime.from(cursor, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      }
      cursor = cursor.add(Duration(minutes: intervalMinutes));
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> applySchedule(AppSettings settings, {bool requestPermissionIfNeeded = false}) async {
    _soundEnabled = settings.soundEnabled;

    if (requestPermissionIfNeeded && settings.reminderEnabled) {
      await requestPermissionsIfNeeded();
    }

    await rescheduleDailyWindow(
      enabled: settings.reminderEnabled,
      wake: _toTimeOfDay(settings.wakeMinutes),
      sleep: _toTimeOfDay(settings.sleepMinutes),
      intervalMinutes: settings.intervalMinutes,
    );
  }

  TimeOfDay _toTimeOfDay(int minutes) => TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  DateTime _atToday(TimeOfDay time, DateTime now) => DateTime(now.year, now.month, now.day, time.hour, time.minute);
}
