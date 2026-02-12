import 'package:sqflite/sqflite.dart';

import '../models/intake_event.dart';
import 'database_helper.dart';

class IntakeRepository {
  IntakeRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<IntakeEvent> addEvent(int amountMl, {DateTime? at}) async {
    final event = IntakeEvent(id: null, timestamp: at ?? DateTime.now(), amountMl: amountMl);
    final db = await _dbHelper.database;
    final id = await db.insert('intake_events', event.toMap()..remove('id'));
    return IntakeEvent(id: id, timestamp: event.timestamp, amountMl: amountMl);
  }

  Future<void> deleteEvent(int id) async {
    final db = await _dbHelper.database;
    await db.delete('intake_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEventById(int id) async {
    await deleteEvent(id);
  }

  Future<IntakeEvent?> fetchLatestEventToday() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch;
    final rows = await db.query(
      'intake_events',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start, end],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return IntakeEvent.fromMap(rows.first);
  }

  Future<bool> undoLatestToday() async {
    final latest = await fetchLatestEventToday();
    if (latest?.id == null) {
      return false;
    }
    await deleteEventById(latest!.id!);
    return true;
  }

  Future<int> sumTodayMl() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_ml), 0) total FROM intake_events WHERE timestamp >= ? AND timestamp < ?',
      [start, end],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalForDay(DateTime day) async {
    final db = await _dbHelper.database;
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day + 1).millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_ml), 0) total FROM intake_events WHERE timestamp >= ? AND timestamp < ?',
      [start, end],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<List<IntakeEvent>> getEventsForDay(DateTime day) async {
    final db = await _dbHelper.database;
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day + 1).millisecondsSinceEpoch;
    final rows = await db.query(
      'intake_events',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start, end],
      orderBy: 'timestamp ASC',
    );
    return rows.map(IntakeEvent.fromMap).toList();
  }

  Future<Map<DateTime, int>> getDailyTotalsForMonth(DateTime month) async {
    final db = await _dbHelper.database;
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final rows = await db.query(
      'intake_events',
      columns: ['timestamp', 'amount_ml'],
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    final result = <DateTime, int>{};
    for (final row in rows) {
      final dt = DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int);
      final day = DateTime(dt.year, dt.month, dt.day);
      result[day] = (result[day] ?? 0) + (row['amount_ml'] as int);
    }
    return result;
  }
}
