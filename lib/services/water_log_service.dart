import 'package:shared_preferences/shared_preferences.dart';

import '../data/intake_repository.dart';
import 'daily_totals_service.dart';

class WaterLogService {
  WaterLogService(this._repository);

  final IntakeRepository _repository;

  static const _lastDayKeyPrefs = 'last_day_key';

  String _todayKey() {
    final today = DateTime.now();
    final year = today.year.toString().padLeft(4, '0');
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _syncDayKey() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final stored = prefs.getString(_lastDayKeyPrefs);
    if (stored == todayKey) {
      return;
    }
    await prefs.setString(_lastDayKeyPrefs, todayKey);
  }

  Future<void> add(int ml) async {
    await _syncDayKey();
    await _repository.addEvent(ml);
    await DailyTotalsService.addToToday(ml);
  }

  Future<bool> undoLast() async {
    await _syncDayKey();
    final latest = await _repository.fetchLatestEventToday();
    if (latest?.id == null) {
      return false;
    }
    await _repository.deleteEventById(latest!.id!);
    final total = await _repository.sumTodayMl();
    await DailyTotalsService.setToday(total);
    return true;
  }

  Future<int> getTodayTotal() async {
    await _syncDayKey();
    return _repository.sumTodayMl();
  }

  Future<int> getTodayCount() async {
    await _syncDayKey();
    return _repository.countTodayEvents();
  }

  Future<void> pruneOld({int keepDays = 30}) async {
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day - keepDays);
    await _repository.deleteEventsBefore(threshold);
  }
}
