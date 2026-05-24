import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'match_list_screen.dart';
import 'win_rate_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _totalMinutes = 0;
  int _monthMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final total = await DbHelper.instance.getTotalPracticeMinutes();
    final month = await DbHelper.instance.getMonthPracticeMinutes();
    setState(() {
      _totalMinutes = total;
      _monthMinutes = month;
    });
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m分';
    return '$h時間$m分';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 今月の練習時間
            _statCard(
              icon: Icons.calendar_today,
              label: '今月の累積練習時間',
              value: _formatMinutes(_monthMinutes),
              color: Colors.blue,
            ),
            const SizedBox(height: 16),

            // 全期間の練習時間
            _statCard(
              icon: Icons.access_time_filled,
              label: '累積練習時間',
              value: _formatMinutes(_totalMinutes),
              color: Colors.green,
            ),
            const SizedBox(height: 32),

            // 勝敗一覧ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatchListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('勝敗一覧', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 勝率ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WinRateScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('勝率', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 13)),
              Text(value, style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ],
      ),
    );
  }
}