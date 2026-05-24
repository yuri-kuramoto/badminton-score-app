import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:badminton_score_app/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedColor = '#2196F3';
  int _totalHours = 0;
  String _currentTitle = '初心者';
  bool _titleExpanded = false;

  final Map<String, Color> _colorMap = {
    '#2196F3': Colors.blue,
    '#4CAF50': Colors.green,
    '#F44336': Colors.red,
    '#9C27B0': Colors.purple,
    '#FF9800': Colors.orange,
    '#E91E63': Colors.pink,
    '#00BCD4': Colors.cyan,
    '#8BC34A': const Color(0xFF8BC34A),
    '#795548': const Color(0xFF795548),
  };

  final List<Map<String, dynamic>> _colorOptions = [
    {'label': 'ブルー', 'color': '#2196F3', 'value': Colors.blue},
    {'label': 'グリーン', 'color': '#4CAF50', 'value': Colors.green},
    {'label': 'レッド', 'color': '#F44336', 'value': Colors.red},
    {'label': 'パープル', 'color': '#9C27B0', 'value': Colors.purple},
    {'label': 'オレンジ', 'color': '#FF9800', 'value': Colors.orange},
    {'label': 'ピンク', 'color': '#E91E63', 'value': Colors.pink},
    {'label': 'シアン', 'color': '#00BCD4', 'value': Colors.cyan},
    {'label': 'ライム', 'color': '#8BC34A', 'value': Color(0xFF8BC34A)},
    {'label': 'ブラウン', 'color': '#795548', 'value': Color(0xFF795548)},
  ];

  final List<Map<String, dynamic>> _titles = [
    {'name': '初心者', 'hours': 0},
    {'name': 'シャトル拾い係', 'hours': 3},
    {'name': 'シャトル拾い係卒業', 'hours': 5},
    {'name': 'コートデビュー', 'hours': 8},
    {'name': 'シャトル追跡者', 'hours': 10},
    {'name': 'ファミバド見習い', 'hours': 12},
    {'name': '体育館常連', 'hours': 15},
    {'name': 'ネット前待機勢', 'hours': 20},
    {'name': 'ラリー初級者', 'hours': 25},
    {'name': 'シャトル観察者', 'hours': 30},
    {'name': 'ファミバドプレイヤー', 'hours': 35},
    {'name': 'ラリー中級者', 'hours': 40},
    {'name': '継続練習者', 'hours': 45},
    {'name': '安定プレイヤー', 'hours': 50},
    {'name': 'サーブ研究家', 'hours': 60},
    {'name': '実力者', 'hours': 70},
    {'name': '体育館第二住民', 'hours': 75},
    {'name': 'ネットの番人', 'hours': 85},
    {'name': 'シャトル破壊者', 'hours': 90},
    {'name': '中級プレイヤー', 'hours': 100},
    {'name': '試合経験者', 'hours': 110},
    {'name': '実戦プレイヤー', 'hours': 120},
    {'name': 'コート適応者', 'hours': 130},
    {'name': '戦術理解者', 'hours': 140},
    {'name': '試合巧者', 'hours': 150},
    {'name': 'シャトルハンター', 'hours': 170},
    {'name': '上級練習者', 'hours': 190},
    {'name': 'コートの守護神', 'hours': 200},
    {'name': '上級プレイヤー', 'hours': 225},
    {'name': '体育館の主', 'hours': 250},
    {'name': '競技上級者', 'hours': 275},
    {'name': '強化プレイヤー', 'hours': 300},
    {'name': 'ファミバド戦士', 'hours': 325},
    {'name': 'ファミバド名人', 'hours': 350},
    {'name': 'ファミバドマスター', 'hours': 375},
    {'name': '上位競技者', 'hours': 400},
    {'name': 'ファミバドの覇者', 'hours': 425},
    {'name': '伝説への一歩', 'hours': 450},
    {'name': 'ファミバドレジェンド', 'hours': 475},
    {'name': 'コートの守護神', 'hours': 500},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DbHelper.instance.getSettings();
    final totalMinutes = await DbHelper.instance.getTotalPracticeMinutes();
    final totalHours = totalMinutes ~/ 60;
    final colorStr = settings['theme_color'] as String? ?? '#2196F3';
    final colorValue = _colorMap[colorStr] ?? Colors.blue;
    MyApp.of(context).updateThemeColor(colorValue);
    setState(() {
      _selectedColor = colorStr;
      _currentTitle = settings['selected_title'] as String? ?? '初心者';
      _totalHours = totalHours;
    });
  }

  Future<void> _saveColor(String color) async {
    await DbHelper.instance.updateSettings({'theme_color': color});
    final colorValue = _colorMap[color] ?? Colors.blue;
    MyApp.of(context).updateThemeColor(colorValue);
    setState(() => _selectedColor = color);
  }

  Future<void> _saveTitle(String title) async {
    await DbHelper.instance.updateSettings({'selected_title': title});
    setState(() => _currentTitle = title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('テーマカラー',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((option) {
                final isSelected = _selectedColor == option['color'];
                return GestureDetector(
                  onTap: () => _saveColor(option['color'] as String),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: option['value'] as Color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(option['label'] as String,
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text('称号',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    '🏆 $_currentTitle',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '累積練習時間：$_totalHours時間',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _titleExpanded = !_titleExpanded),
              child: Row(
                children: [
                  Icon(
                    _titleExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                  Text(
                    _titleExpanded ? '称号一覧を閉じる' : '称号一覧を見る',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (_titleExpanded)
              ..._titles.map((t) {
                final hours = t['hours'] as int;
                final name = t['name'] as String;
                final achieved = _totalHours >= hours;
                final isSelected = _currentTitle == name;
                final remaining = hours - _totalHours;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    onTap: achieved ? () => _saveTitle(name) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.amber.shade100
                            : achieved
                                ? Colors.grey.shade50
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.amber.shade400
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : achieved
                                    ? Icons.circle_outlined
                                    : Icons.lock,
                            color: isSelected
                                ? Colors.amber
                                : achieved
                                    ? Colors.grey
                                    : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: achieved
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                Text(
                                  achieved
                                      ? '$hours時間以上で解放'
                                      : 'あと${remaining}時間で解放',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: achieved
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Text('使用中',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.amber)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}