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
  // 練習開始を記録
    Future<int> startPractice() async {
      final db = await database;
      final now = DateTime.now();
      return await db.insert('practice_sessions', {
        'started_at': now.toIso8601String(),
        'practice_date': now.toIso8601String().substring(0, 10),
      });
    }

    // 練習終了を記録
    Future<void> endPractice(int id) async {
      final db = await database;
      final now = DateTime.now();
      final session = await db.query(
        'practice_sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (session.isEmpty) return;

      final startedAt = DateTime.parse(session.first['started_at'] as String);
      final duration = now.difference(startedAt).inMinutes;

      await db.update(
        'practice_sessions',
        {
          'ended_at': now.toIso8601String(),
          'duration_minutes': duration,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    // 試合を保存
      Future<int> insertMatch(Map<String, dynamic> data) async {
        final db = await database;
        return await db.insert('matches', data);
      }

      // メンバーを保存
      Future<void> insertMatchMember(Map<String, dynamic> data) async {
        final db = await database;
        await db.insert('match_members', data);
      }
}