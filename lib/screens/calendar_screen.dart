import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'calendar_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<String, int> _practiceMinutes = {}; // 日付 → 練習時間（分）

  @override
  void initState() {
    super.initState();
    _loadPracticeData();
  }

  Future<void> _loadPracticeData() async {
    final data = await DbHelper.instance.getPracticeMinutesByDate();
    setState(() => _practiceMinutes = data);
  }

  Color _cellColor(int? minutes) {
    if (minutes == null || minutes == 0) return Colors.white;
    if (minutes < 60) return const Color(0xFFc6e48b);
    if (minutes < 180) return const Color(0xFF7bc96f);
    return const Color(0xFF239a3b);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    // 月の最初の曜日（0=月〜6=日）
    final firstWeekday = firstDay.weekday % 7; // 日曜始まりに変換

    return Scaffold(
      appBar: AppBar(
        title: Text('${now.year}年${now.month}月'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 曜日ヘッダー
            Row(
              children: ['日', '月', '火', '水', '木', '金', '土'].map((d) =>
                Expanded(
                  child: Center(
                    child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 8),

            // カレンダーグリッド
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: firstWeekday + lastDay.day,
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox();

                final day = index - firstWeekday + 1;
                final date = DateTime(now.year, now.month, day);
                final dateStr = date.toIso8601String().substring(0, 10);
                final minutes = _practiceMinutes[dateStr];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarDetailScreen(date: date),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cellColor(minutes),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          color: minutes != null && minutes >= 60
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 凡例
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend(Colors.white, '0分'),
                const SizedBox(width: 12),
                _legend(const Color(0xFFc6e48b), '〜1時間'),
                const SizedBox(width: 12),
                _legend(const Color(0xFF7bc96f), '〜3時間'),
                const SizedBox(width: 12),
                _legend(const Color(0xFF239a3b), '3時間以上'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}