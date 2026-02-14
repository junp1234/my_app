import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DailyTotalsService {
  static const _prefsKey = 'daily_totals_v1';

  static String _formatDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime? _parseDate(String key) {
    final parts = key.split('-');
    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static Future<Map<String, int>> loadMap() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      final result = <String, int>{};
      decoded.forEach((key, value) {
        if (value is int) {
          result[key] = value;
        } else if (value is num) {
          result[key] = value.toInt();
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> addToToday(int ml) async {
    final map = await loadMap();
    final now = DateTime.now();
    final todayKey = _formatDate(now);
    final current = map[todayKey] ?? 0;
    map[todayKey] = current + ml;
    await _saveWithPrune(map);
  }

  static Future<void> setToday(int ml) async {
    final map = await loadMap();
    final now = DateTime.now();
    final todayKey = _formatDate(now);
    map[todayKey] = ml;
    await _saveWithPrune(map);
  }

  static Future<Map<DateTime, int>> getLastNDays(int n) async {
    final map = await loadMap();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final result = <DateTime, int>{};
    for (var i = 0; i < n; i++) {
      final day = DateTime(today.year, today.month, today.day - i);
      result[day] = map[_formatDate(day)] ?? 0;
    }
    return result;
  }

  static Future<void> _saveWithPrune(Map<String, int> map) async {
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day - 30);

    final pruned = <String, int>{};
    map.forEach((key, value) {
      final parsed = _parseDate(key);
      if (parsed != null && !parsed.isBefore(threshold)) {
        pruned[key] = value;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(pruned));
  }
}
