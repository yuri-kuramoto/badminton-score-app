import 'package:flutter/material.dart';
import 'database/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ファミバド',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPracticing = false;
  DateTime? _startTime;

  void _togglePractice() {
    setState(() {
      if (_isPracticing) {
        // 練習終了
        _isPracticing = false;
        // TODO: 練習時間を保存
      } else {
        // 練習開始
        _isPracticing = true;
        _startTime = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ファミバド'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 称号表示
            const Text(
              '初心者',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // 練習開始/終了ボタン
            ElevatedButton(
              onPressed: _togglePractice,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPracticing ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              ),
              child: Text(
                _isPracticing ? '練習終了' : '練習開始',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 40),

            // ナビゲーションボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navButton(Icons.sports, '試合登録'),
                _navButton(Icons.calendar_month, 'カレンダー'),
                _navButton(Icons.bar_chart, '分析'),
                _navButton(Icons.settings, '設定'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          onPressed: () {}, // TODO: 画面遷移
          icon: Icon(icon, size: 32),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}