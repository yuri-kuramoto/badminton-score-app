import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class CalendarDetailScreen extends StatefulWidget {
  final DateTime date;

  const CalendarDetailScreen({super.key, required this.date});

  @override
  State<CalendarDetailScreen> createState() => _CalendarDetailScreenState();
}

class _CalendarDetailScreenState extends State<CalendarDetailScreen> {
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final data = await DbHelper.instance.getPracticeSessionsByDate(
      widget.date.toIso8601String().substring(0, 10),
    );
    setState(() => _sessions = data);
  }

  String _formatTime(String isoString) {
    final dt = DateTime.parse(isoString);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m分';
    return '$h時間$m分';
  }

  Future<void> _showEditDialog({Map<String, dynamic>? session}) async {
    final isEdit = session != null;
    TimeOfDay startTime = isEdit
        ? TimeOfDay.fromDateTime(DateTime.parse(session['started_at']))
        : TimeOfDay.now();
    TimeOfDay endTime = isEdit && session['ended_at'] != null
        ? TimeOfDay.fromDateTime(DateTime.parse(session['ended_at']))
        : TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '練習記録を編集' : '練習記録を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('開始時刻'),
                trailing: Text(startTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setDialogState(() => startTime = picked);
                },
              ),
              ListTile(
                title: const Text('終了時刻'),
                trailing: Text(endTime.format(context)),
                onTap: () async {
                 final picked = await showTimePicker(
                   context: context,
                   initialTime: startTime,
                   builder: (context, child) {
                     return MediaQuery(
                       data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                       child: child!,
                     );
                   },
                 );
                  if (picked != null) setDialogState(() => endTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final date = widget.date;
                final startedAt = DateTime(date.year, date.month, date.day,
                    startTime.hour, startTime.minute);
                final endedAt = DateTime(date.year, date.month, date.day,
                    endTime.hour, endTime.minute);
                final duration = endedAt.difference(startedAt).inMinutes;

                if (duration <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('終了時刻は開始時刻より後にしてください')),
                  );
                  return;
                }

                if (isEdit) {
                  await DbHelper.instance.updatePracticeSession(
                    session['id'] as int,
                    startedAt,
                    endedAt,
                    duration,
                  );
                } else {
                  await DbHelper.instance.insertPracticeSession(
                    startedAt,
                    endedAt,
                    duration,
                    widget.date.toIso8601String().substring(0, 10),
                  );
                }
                if (mounted) Navigator.pop(context);
                _loadSessions();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSession(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbHelper.instance.deletePracticeSession(id);
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.date.year}年${widget.date.month}月${widget.date.day}日';
    final totalMinutes = _sessions.fold<int>(
      0, (sum, s) => sum + (s['duration_minutes'] as int? ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '合計練習時間：${_formatDuration(totalMinutes)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text('練習記録', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _sessions.isEmpty
                ? const Text('この日の練習記録はありません')
                : Expanded(
                    child: ListView.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final s = _sessions[index];
                        final start = _formatTime(s['started_at'] as String);
                        final end = s['ended_at'] != null
                            ? _formatTime(s['ended_at'] as String)
                            : '記録中';
                        final duration = s['duration_minutes'] as int? ?? 0;

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.access_time),
                            title: Text('$start 〜 $end'),
                            subtitle: Text(_formatDuration(duration)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditDialog(session: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSession(s['id'] as int),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}