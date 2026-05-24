import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'calendar_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<String, int> _practiceMinutes = {};
  DateTime _currentMonth = DateTime.now();
  int _monthTotalMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadPracticeData();
  }

  Future<void> _loadPracticeData() async {
    final data = await DbHelper.instance.getPracticeMinutesByDate();
    final monthStr =
        '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    final total = data.entries
        .where((e) => e.key.startsWith(monthStr))
        .fold(0, (sum, e) => sum + e.value);
    setState(() {
      _practiceMinutes = data;
      _monthTotalMinutes = total;
    });
  }

  Future<void> _showMonthPicker() async {
    int selectedYear = _currentMonth.year;
    int selectedMonth = _currentMonth.month;
    final now = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('年月を選択'),
          content: Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  value: selectedYear,
                  isExpanded: true,
                  items: List.generate(
                    now.year - 2024,
                    (i) => DropdownMenuItem(
                      value: now.year - i,
                      child: Text('${now.year - i}年'),
                    ),
                  ),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedYear = v!;
                      if (selectedYear == now.year && selectedMonth > now.month) {
                        selectedMonth = now.month;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  value: selectedMonth,
                  isExpanded: true,
                  items: List.generate(12, (i) => i + 1)
                      .where((m) => !(selectedYear == now.year && m > now.month))
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m月'),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedMonth = v!),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(selectedYear, selectedMonth);
                });
                _loadPracticeData();
                Navigator.pop(context);
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  Color _cellColor(int? minutes) {
    if (minutes == null || minutes == 0) return Colors.white;
    if (minutes < 60) return const Color(0xFFc6e48b);
    if (minutes < 180) return const Color(0xFF7bc96f);
    return const Color(0xFF239a3b);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadPracticeData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) return;
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadPracticeData();
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m分';
    return '$h時間$m分';
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7;
    final now = DateTime.now();
    final isCurrentMonth =
        _currentMonth.year == now.year && _currentMonth.month == now.month;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _prevMonth,
            ),
            GestureDetector(
              onTap: () => _showMonthPicker(),
              child: Text(
                '${_currentMonth.year}年${_currentMonth.month}月',
                style: const TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: isCurrentMonth ? Colors.grey.shade300 : null,
              ),
              onPressed: isCurrentMonth ? null : _nextMonth,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: ['日', '月', '火', '水', '木', '金', '土']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
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
                final date =
                    DateTime(_currentMonth.year, _currentMonth.month, day);
                final dateStr = date.toIso8601String().substring(0, 10);
                final minutes = _practiceMinutes[dateStr];

                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarDetailScreen(date: date),
                      ),
                    );
                    _loadPracticeData();
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
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentMonth.month}月の合計練習時間：${_formatMinutes(_monthTotalMinutes)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
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