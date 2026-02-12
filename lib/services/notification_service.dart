import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _nextReminderNotificationId = 100;

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
    var granted = true;

    final iosImplementation = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosImplementation?.requestPermissions(alert: true, badge: false, sound: true);
    if (iosGranted != null) {
      granted = granted && iosGranted;
    }

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await androidImplementation?.requestNotificationsPermission();
    if (androidGranted != null) {
      granted = granted && androidGranted;
    }

    return granted;
  }

  Future<void> scheduleNextReminder({
    required bool enabled,
    required TimeOfDay wake,
    required TimeOfDay sleep,
    required int intervalMinutes,
  }) async {
    await cancelAll();
    if (!enabled || intervalMinutes <= 0) {
      return;
    }

    final now = DateTime.now();
    final nextDateTime = _nextReminderDateTime(now, wake, sleep, intervalMinutes);
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'reminder',
        'Reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(presentSound: _soundEnabled),
    );

    await _plugin.zonedSchedule(
      _nextReminderNotificationId,
      '水を飲もう',
      'コップ1杯の水分補給をしましょう',
      tz.TZDateTime.from(nextDateTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  DateTime _nextReminderDateTime(DateTime now, TimeOfDay wake, TimeOfDay sleep, int intervalMinutes) {
    final wakeToday = DateTime(now.year, now.month, now.day, wake.hour, wake.minute);
    var sleepToday = DateTime(now.year, now.month, now.day, sleep.hour, sleep.minute);

    if (!sleepToday.isAfter(wakeToday)) {
      sleepToday = sleepToday.add(const Duration(days: 1));
    }

    if (now.isBefore(wakeToday)) {
      return wakeToday;
    }

    if (now.isAfter(sleepToday)) {
      return wakeToday.add(const Duration(days: 1));
    }

    var cursor = wakeToday;
    while (!cursor.isAfter(sleepToday)) {
      if (cursor.isAfter(now)) {
        return cursor;
      }
      cursor = cursor.add(Duration(minutes: intervalMinutes));
    }

    return wakeToday.add(const Duration(days: 1));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> applySchedule(AppSettings settings, {bool requestPermissionIfNeeded = false}) async {
    _soundEnabled = settings.soundEnabled;

    if (requestPermissionIfNeeded && settings.reminderEnabled) {
      await requestPermissionsIfNeeded();
    }

    await scheduleNextReminder(
      enabled: settings.reminderEnabled,
      wake: _toTimeOfDay(settings.wakeMinutes),
      sleep: _toTimeOfDay(settings.sleepMinutes),
      intervalMinutes: settings.intervalMinutes,
    );
  }

  TimeOfDay _toTimeOfDay(int minutes) => TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}
