import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper({
    String databaseName = 'drop_glass.db',
    this.version = 1,
    this.onCreate,
  }) : _databaseName = databaseName;

  static final DatabaseHelper instance = DatabaseHelper();

  final String _databaseName;
  final int version;
  final Future<void> Function(Database db, int version)? onCreate;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, _databaseName),
      version: version,
      onCreate: onCreate ?? _defaultOnCreate,
    );
    return _db!;
  }

  Future<void> _defaultOnCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE intake_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            amount_ml INTEGER NOT NULL
          )
        ''');
  }
}
