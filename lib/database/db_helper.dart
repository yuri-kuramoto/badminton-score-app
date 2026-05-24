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
      // 日付ごとの練習時間を取得
        Future<Map<String, int>> getPracticeMinutesByDate() async {
          final db = await database;
          final result = await db.rawQuery('''
            SELECT practice_date, SUM(duration_minutes) as total
            FROM practice_sessions
            WHERE duration_minutes IS NOT NULL
            GROUP BY practice_date
          ''');

          final map = <String, int>{};
          for (final row in result) {
            map[row['practice_date'] as String] = (row['total'] as int?) ?? 0;
          }
          return map;
        }

        // 特定の日の練習セッション一覧を取得
        Future<List<Map<String, dynamic>>> getPracticeSessionsByDate(String date) async {
          final db = await database;
          return await db.query(
            'practice_sessions',
            where: 'practice_date = ?',
            whereArgs: [date],
            orderBy: 'started_at ASC',
          );
        }
        // 練習記録を手動追加
          Future<void> insertPracticeSession(
            DateTime startedAt,
            DateTime endedAt,
            int duration,
            String practiceDate,
          ) async {
            final db = await database;
            await db.insert('practice_sessions', {
              'started_at': startedAt.toIso8601String(),
              'ended_at': endedAt.toIso8601String(),
              'duration_minutes': duration,
              'practice_date': practiceDate,
            });
          }

          // 練習記録を編集
          Future<void> updatePracticeSession(
            int id,
            DateTime startedAt,
            DateTime endedAt,
            int duration,
          ) async {
            final db = await database;
            await db.update(
              'practice_sessions',
              {
                'started_at': startedAt.toIso8601String(),
                'ended_at': endedAt.toIso8601String(),
                'duration_minutes': duration,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }

          // 練習記録を削除
          Future<void> deletePracticeSession(int id) async {
            final db = await database;
            await db.delete(
              'practice_sessions',
              where: 'id = ?',
              whereArgs: [id],
            );
          }
          // 累積練習時間（全期間）
            Future<int> getTotalPracticeMinutes() async {
              final db = await database;
              final result = await db.rawQuery(
                'SELECT SUM(duration_minutes) as total FROM practice_sessions WHERE duration_minutes IS NOT NULL'
              );
              return (result.first['total'] as int?) ?? 0;
            }

            // 今月の練習時間
            Future<int> getMonthPracticeMinutes() async {
              final db = await database;
              final now = DateTime.now();
              final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
              final result = await db.rawQuery(
                'SELECT SUM(duration_minutes) as total FROM practice_sessions WHERE practice_date LIKE ? AND duration_minutes IS NOT NULL',
                ['$monthStr%'],
              );
              return (result.first['total'] as int?) ?? 0;
            }

            // 試合一覧取得（フィルター付き）
            Future<List<Map<String, dynamic>>> getMatches({
              String? matchType,
              String? result,
            }) async {
              final db = await database;
              String where = '';
              List<dynamic> args = [];

              if (matchType != null) {
                where += 'match_type = ?';
                args.add(matchType);
              }
              if (result != null) {
                if (where.isNotEmpty) where += ' AND ';
                where += 'result = ?';
                args.add(result);
              }

              return await db.query(
                'matches',
                where: where.isEmpty ? null : where,
                whereArgs: args.isEmpty ? null : args,
                orderBy: 'match_date DESC',
              );
            }

            // 勝率取得
            Future<Map<String, dynamic>> getWinRate(String matchType) async {
              final db = await database;
              final result = await db.rawQuery('''
                SELECT
                  COUNT(*) as total,
                  SUM(CASE WHEN result = '勝ち' THEN 1 ELSE 0 END) as wins,
                  SUM(CASE WHEN result = '負け' THEN 1 ELSE 0 END) as losses,
                  SUM(CASE WHEN result = '引き分け' THEN 1 ELSE 0 END) as draws
                FROM matches
                WHERE match_type = ?
              ''', [matchType]);

              return {
                'total': result.first['total'] as int? ?? 0,
                'wins': result.first['wins'] as int? ?? 0,
                'losses': result.first['losses'] as int? ?? 0,
                'draws': result.first['draws'] as int? ?? 0,
              };
            }
            // 時間かぶりチェック
              Future<bool> hasPracticeOverlap(
                String date,
                DateTime startedAt,
                DateTime endedAt, {
                int? excludeId,
              }) async {
                final db = await database;
                String where =
                    'practice_date = ? AND ended_at IS NOT NULL AND started_at < ? AND ended_at > ?';
                List<dynamic> args = [
                  date,
                  endedAt.toIso8601String(),
                  startedAt.toIso8601String(),
                ];

                if (excludeId != null) {
                  where += ' AND id != ?';
                  args.add(excludeId);
                }

                final result = await db.query(
                  'practice_sessions',
                  where: where,
                  whereArgs: args,
                );
                return result.isNotEmpty;
              }
}