import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('famibado.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE practice_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        duration_minutes INTEGER,
        practice_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_date TEXT NOT NULL,
        match_type TEXT NOT NULL,
        my_score INTEGER NOT NULL,
        opponent_score INTEGER NOT NULL,
        result TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE match_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        side TEXT NOT NULL,
        FOREIGN KEY (match_id) REFERENCES matches (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE titles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        required_hours INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        theme_color TEXT NOT NULL DEFAULT '#2196F3',
        current_title_id INTEGER,
        FOREIGN KEY (current_title_id) REFERENCES titles (id)
      )
    ''');

    await db.execute('''
      INSERT INTO titles (name, required_hours) VALUES
        ('初心者', 0),
        ('中級者', 30),
        ('努力家', 100),
        ('バド戦士', 200)
    ''');

    await db.execute('''
      INSERT INTO settings (theme_color, current_title_id) VALUES ('#2196F3', 1)
    ''');
  }
}