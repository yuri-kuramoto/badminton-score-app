import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  List<Map<String, dynamic>> _matches = [];
  String _filterType = 'all'; // all, practice, tournament
  String _filterResult = 'all'; // all, 勝ち, 負け, 引き分け

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final data = await DbHelper.instance.getMatches(
      matchType: _filterType == 'all' ? null : _filterType,
      result: _filterResult == 'all' ? null : _filterResult,
    );
    setState(() => _matches = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('勝敗一覧'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // フィルター
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(
                      labelText: '種別',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('すべて')),
                      DropdownMenuItem(value: 'practice', child: Text('練習試合')),
                      DropdownMenuItem(value: 'tournament', child: Text('大会')),
                    ],
                    onChanged: (v) {
                      setState(() => _filterType = v!);
                      _loadMatches();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterResult,
                    decoration: const InputDecoration(
                      labelText: '結果',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('すべて')),
                      DropdownMenuItem(value: '勝ち', child: Text('勝ち')),
                      DropdownMenuItem(value: '負け', child: Text('負け')),
                      DropdownMenuItem(value: '引き分け', child: Text('引き分け')),
                    ],
                    onChanged: (v) {
                      setState(() => _filterResult = v!);
                      _loadMatches();
                    },
                  ),
                ),
              ],
            ),
          ),

          // 一覧
          Expanded(
            child: _matches.isEmpty
                ? const Center(child: Text('試合記録がありません'))
                : ListView.builder(
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final m = _matches[index];
                      final result = m['result'] as String;
                      final color = result == '勝ち'
                          ? Colors.blue
                          : result == '負け'
                              ? Colors.red
                              : Colors.orange;
                      final type = m['match_type'] == 'practice' ? '練習' : '大会';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color,
                            child: Text(
                              result == '勝ち' ? '勝' : result == '負け' ? '負' : '分',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${m['my_score']} - ${m['opponent_score']}'),
                          subtitle: Text('${m['match_date']}　$type'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color),
                            ),
                            child: Text(result, style: TextStyle(color: color)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}