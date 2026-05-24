import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class MatchRecordScreen extends StatefulWidget {
  final String matchType;

  const MatchRecordScreen({super.key, required this.matchType});

  @override
  State<MatchRecordScreen> createState() => _MatchRecordScreenState();
}

class _MatchRecordScreenState extends State<MatchRecordScreen> {
  final _myScoreController = TextEditingController();
  final _opponentScoreController = TextEditingController();
  final List<TextEditingController> _myMembersControllers =
      List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _opponentMembersControllers =
      List.generate(3, (_) => TextEditingController());
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _myScoreController.dispose();
    _opponentScoreController.dispose();
    for (final c in _myMembersControllers) c.dispose();
    for (final c in _opponentMembersControllers) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final myScore = int.tryParse(_myScoreController.text);
    final opponentScore = int.tryParse(_opponentScoreController.text);

    if (myScore == null || opponentScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('点数を入力してください')),
      );
      return;
    }

   final result = myScore > opponentScore ? '勝ち' : myScore == opponentScore ? '引き分け' : '負け';

    final matchId = await DbHelper.instance.insertMatch({
      'match_date': _selectedDate.toIso8601String().substring(0, 10),
      'match_type': widget.matchType,
      'my_score': myScore,
      'opponent_score': opponentScore,
      'result': result,
    });

    // メンバー保存（名前が入力されてるものだけ）
    for (final c in _myMembersControllers) {
      if (c.text.isNotEmpty) {
        await DbHelper.instance.insertMatchMember({
          'match_id': matchId,
          'name': c.text,
          'side': 'mine',
        });
      }
    }
    for (final c in _opponentMembersControllers) {
      if (c.text.isNotEmpty) {
        await DbHelper.instance.insertMatchMember({
          'match_id': matchId,
          'name': c.text,
          'side': 'opponent',
        });
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$result で保存しました！')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.matchType == 'practice' ? '練習試合記録' : '大会試合記録';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付
            Row(
              children: [
                const Text('日付：', style: TextStyle(fontSize: 16)),
                TextButton(
                  onPressed: _pickDate,
                  child: Text(
                    _selectedDate.toIso8601String().substring(0, 10),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // スコア
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _myScoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '自分の点数',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('vs', style: TextStyle(fontSize: 20)),
                ),
                Expanded(
                  child: TextField(
                    controller: _opponentScoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '相手の点数',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 自分のメンバー
            const Text('自分のチーム（任意）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _myMembersControllers[i],
                decoration: InputDecoration(
                  labelText: 'メンバー ${i + 1}',
                  border: const OutlineInputBorder(),
                ),
              ),
            )),
            const SizedBox(height: 16),

            // 相手のメンバー
            const Text('相手のチーム（任意）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _opponentMembersControllers[i],
                decoration: InputDecoration(
                  labelText: 'メンバー ${i + 1}',
                  border: const OutlineInputBorder(),
                ),
              ),
            )),
            const SizedBox(height: 32),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('保存', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}