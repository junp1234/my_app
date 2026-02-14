import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/database_helper.dart';
import 'package:my_app/data/intake_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('deleteTodayEvents clears only today records', () async {
    final dbName = 'delete_today_events_test.db';
    final helper = DatabaseHelper(databaseName: dbName);
    final repository = IntakeRepository(dbHelper: helper);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    await repository.addEvent(300, at: now.subtract(const Duration(minutes: 2)));
    await repository.addEvent(200, at: now.subtract(const Duration(minutes: 1)));
    await repository.addEvent(150, at: yesterday);

    expect(await repository.sumTodayMl(), 500);
    expect(await repository.getTotalForDay(yesterday), 150);

    final deleted = await repository.deleteTodayEvents();

    expect(deleted, 2);
    expect(await repository.sumTodayMl(), 0);
    expect(await repository.getTotalForDay(yesterday), 150);

    final db = await helper.database;
    await db.close();
    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/$dbName');
  });

  test('undoLatestToday removes three latest events and then returns false', () async {
    final dbName = 'undo_latest_today_test.db';
    final helper = DatabaseHelper(databaseName: dbName);
    final repository = IntakeRepository(dbHelper: helper);

    final now = DateTime.now();
    await repository.addEvent(200, at: now.subtract(const Duration(minutes: 3)));
    await repository.addEvent(300, at: now.subtract(const Duration(minutes: 2)));
    await repository.addEvent(400, at: now.subtract(const Duration(minutes: 1)));

    expect(await repository.getTotalForDay(now), 900);
    expect(await repository.sumTodayMl(), 900);

    expect(await repository.undoLatestToday(), isTrue);
    expect(await repository.getTotalForDay(now), 500);
    expect(await repository.sumTodayMl(), 500);

    expect(await repository.undoLatestToday(), isTrue);
    expect(await repository.getTotalForDay(now), 200);
    expect(await repository.sumTodayMl(), 200);

    expect(await repository.undoLatestToday(), isTrue);
    expect(await repository.getTotalForDay(now), 0);
    expect(await repository.sumTodayMl(), 0);

    expect(await repository.undoLatestToday(), isFalse);

    final db = await helper.database;
    await db.close();
    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/$dbName');
  });

  test('getDailyTotalsForMonth returns local date keys and sums only focused month', () async {
    final dbName = 'month_totals_test.db';
    final helper = DatabaseHelper(databaseName: dbName);
    final repository = IntakeRepository(dbHelper: helper);

    final targetMonth = DateTime(2025, 2);
    await repository.addEvent(200, at: DateTime(2025, 2, 1, 9));
    await repository.addEvent(300, at: DateTime(2025, 2, 1, 20));
    await repository.addEvent(150, at: DateTime(2025, 2, 14, 12));
    await repository.addEvent(500, at: DateTime(2025, 3, 1, 0));

    final totals = await repository.getDailyTotalsForMonth(targetMonth);

    expect(totals['2025-02-01'], 500);
    expect(totals['2025-02-14'], 150);
    expect(totals.containsKey('2025-03-01'), isFalse);

    final db = await helper.database;
    await db.close();
    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/$dbName');
  });
  test('countTodayEvents and deleteEventsBefore keep recent day records', () async {
    final dbName = 'count_and_prune_test.db';
    final helper = DatabaseHelper(databaseName: dbName);
    final repository = IntakeRepository(dbHelper: helper);

    final now = DateTime.now();
    final tenDaysAgo = now.subtract(const Duration(days: 10));
    final fortyDaysAgo = now.subtract(const Duration(days: 40));

    await repository.addEvent(250, at: now.subtract(const Duration(minutes: 5)));
    await repository.addEvent(300, at: tenDaysAgo);
    await repository.addEvent(120, at: fortyDaysAgo);

    expect(await repository.countTodayEvents(), 1);

    final deleted = await repository.deleteEventsBefore(now.subtract(const Duration(days: 30)));

    expect(deleted, 1);
    expect(await repository.getTotalForDay(tenDaysAgo), 300);
    expect(await repository.sumTodayMl(), 250);

    final db = await helper.database;
    await db.close();
    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/$dbName');
  });

}
