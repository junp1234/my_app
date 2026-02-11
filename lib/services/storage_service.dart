import 'dart:math';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HydrationState {
  HydrationState({
    required this.goalMl,
    required this.servingMl,
    required this.todayIntakeMl,
    required this.lastDrinkMl,
  });

  final int goalMl;
  final int servingMl;
  final int todayIntakeMl;
  final int lastDrinkMl;
}

class DrinkUpdate {
  DrinkUpdate({
    required this.todayIntakeMl,
    required this.lastDrinkMl,
  });

  final int todayIntakeMl;
  final int lastDrinkMl;
}

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _goalKey = 'goal_ml';
  static const _servingKey = 'serving_ml';
  static const _intakeKey = 'today_intake_ml';
  static const _dateKey = 'saved_date';
  static const _lastDrinkKey = 'last_drink_ml';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<HydrationState> loadHydrationState() async {
    final prefs = await _prefs;
    final today = _todayString();
    final savedDate = prefs.getString(_dateKey);

    if (savedDate != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setInt(_intakeKey, 0);
      await prefs.setInt(_lastDrinkKey, 0);
    }

    return HydrationState(
      goalMl: prefs.getInt(_goalKey) ?? 2000,
      servingMl: prefs.getInt(_servingKey) ?? 200,
      todayIntakeMl: prefs.getInt(_intakeKey) ?? 0,
      lastDrinkMl: prefs.getInt(_lastDrinkKey) ?? 0,
    );
  }

  Future<DrinkUpdate> applyDrinkDelta({
    required int deltaMl,
    required int nextLastDrinkMl,
  }) async {
    final prefs = await _prefs;
    await _ensureToday(prefs);

    final current = prefs.getInt(_intakeKey) ?? 0;
    final updated = max(0, current + deltaMl);

    await prefs.setInt(_intakeKey, updated);
    await prefs.setInt(_lastDrinkKey, max(0, nextLastDrinkMl));

    return DrinkUpdate(
      todayIntakeMl: updated,
      lastDrinkMl: max(0, nextLastDrinkMl),
    );
  }

  Future<void> saveSettings({required int goalMl, required int servingMl}) async {
    final prefs = await _prefs;
    await prefs.setInt(_goalKey, goalMl);
    await prefs.setInt(_servingKey, servingMl);
  }

  Future<void> _ensureToday(SharedPreferences prefs) async {
    final today = _todayString();
    final savedDate = prefs.getString(_dateKey);

    if (savedDate != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setInt(_intakeKey, 0);
      await prefs.setInt(_lastDrinkKey, 0);
    }
  }

  String _todayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
