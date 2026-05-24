import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class WinRateScreen extends StatefulWidget {
  const WinRateScreen({super.key});

  @override
  State<WinRateScreen> createState() => _WinRateScreenState();
}

class _WinRateScreenState extends State<WinRateScreen> {
  Map<String, dynamic> _practiceStats = {};
  Map<String, dynamic> _tournamentStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final practice = await DbHelper.instance.getWinRate('practice');
    final tournament = await DbHelper.instance.getWinRate('tournament');
    setState(() {
      _practiceStats = practice;
      _tournamentStats = tournament;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('勝率'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _winRateCard('練習試合', _practiceStats, Colors.blue),
            const SizedBox(height: 24),
            _winRateCard('大会', _tournamentStats, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _winRateCard(String title, Map<String, dynamic> stats, Color color) {
    final total = stats['total'] as int? ?? 0;
    final wins = stats['wins'] as int? ?? 0;
    final losses = stats['losses'] as int? ?? 0;
    final draws = stats['draws'] as int? ?? 0;
    final rate = total == 0 ? 0.0 : wins / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          )),
          const SizedBox(height: 16),
          // 勝率バー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 16,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '勝率 ${(rate * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('総試合', '$total', Colors.grey),
              _statItem('勝ち', '$wins', Colors.blue),
              _statItem('負け', '$losses', Colors.red),
              _statItem('引き分け', '$draws', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color,
        )),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}