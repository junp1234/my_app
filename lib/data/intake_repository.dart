import 'package:sqflite/sqflite.dart';

import '../models/intake_event.dart';
import 'database_helper.dart';

class IntakeRepository {
  IntakeRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  ({int start, int end}) _dayRange(DateTime day) {
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day + 1).millisecondsSinceEpoch;
    return (start: start, end: end);
  }

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
    final range = _dayRange(DateTime.now());
    final rows = await db.query(
      'intake_events',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [range.start, range.end],
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
    final range = _dayRange(DateTime.now());
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_ml), 0) total FROM intake_events WHERE timestamp >= ? AND timestamp < ?',
      [range.start, range.end],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<int> deleteTodayEvents() async {
    final db = await _dbHelper.database;
    final range = _dayRange(DateTime.now());
    return db.delete(
      'intake_events',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [range.start, range.end],
    );
  }

  Future<int> getTotalForDay(DateTime day) async {
    final db = await _dbHelper.database;
    final range = _dayRange(day);
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_ml), 0) total FROM intake_events WHERE timestamp >= ? AND timestamp < ?',
      [range.start, range.end],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<List<IntakeEvent>> getEventsForDay(DateTime day) async {
    final db = await _dbHelper.database;
    final range = _dayRange(day);
    final rows = await db.query(
      'intake_events',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [range.start, range.end],
      orderBy: 'timestamp ASC',
    );
    return rows.map(IntakeEvent.fromMap).toList();
  }

  Future<Map<String, int>> getDailyTotalsForMonth(DateTime monthLocal) async {
    final db = await _dbHelper.database;
    final start = DateTime(monthLocal.year, monthLocal.month);
    final end = DateTime(monthLocal.year, monthLocal.month + 1);
    final rows = await db.query(
      'intake_events',
      columns: ['timestamp', 'amount_ml'],
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    final result = <String, int>{};
    for (final row in rows) {
      final dt = DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int);
      final key = _dateKey(DateTime(dt.year, dt.month, dt.day));
      result[key] = (result[key] ?? 0) + (row['amount_ml'] as int);
    }
    return result;
  }
}
