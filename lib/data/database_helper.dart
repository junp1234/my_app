import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'drop_glass.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE intake_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            amount_ml INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }
}
