import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository._();

  static final SettingsRepository instance = SettingsRepository._();

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      dailyGoalMl: prefs.getInt('dailyGoalMl') ?? AppSettings.defaults.dailyGoalMl,
      stepMl: prefs.getInt('stepMl') ?? AppSettings.defaults.stepMl,
      reminderEnabled: prefs.getBool('reminderEnabled') ?? AppSettings.defaults.reminderEnabled,
      wakeMinutes: prefs.getInt('wakeMinutes') ?? AppSettings.defaults.wakeMinutes,
      sleepMinutes: prefs.getInt('sleepMinutes') ?? AppSettings.defaults.sleepMinutes,
      intervalMinutes: prefs.getInt('intervalMinutes') ?? AppSettings.defaults.intervalMinutes,
      soundEnabled: prefs.getBool('soundEnabled') ?? AppSettings.defaults.soundEnabled,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoalMl', settings.dailyGoalMl);
    await prefs.setInt('stepMl', settings.stepMl);
    await prefs.setBool('reminderEnabled', settings.reminderEnabled);
    await prefs.setInt('wakeMinutes', settings.wakeMinutes);
    await prefs.setInt('sleepMinutes', settings.sleepMinutes);
    await prefs.setInt('intervalMinutes', settings.intervalMinutes);
    await prefs.setBool('soundEnabled', settings.soundEnabled);
  }
}
