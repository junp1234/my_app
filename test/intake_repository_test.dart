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
}
