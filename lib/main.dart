import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'screens/match_register_screen.dart';

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
  int? _currentSessionId;
  Duration _elapsed = Duration.zero;
  late final Stream<Duration> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (_) {
      if (_isPracticing && _startTime != null) {
        return DateTime.now().difference(_startTime!);
      }
      return Duration.zero;
    });
  }

  void _togglePractice() async {
    if (_isPracticing) {
      // 練習終了
      await DbHelper.instance.endPractice(_currentSessionId!);
      setState(() {
        _isPracticing = false;
        _elapsed = Duration.zero;
        _currentSessionId = null;
        _startTime = null;
      });
    } else {
      // 練習開始
      final id = await DbHelper.instance.startPractice();
      setState(() {
        _isPracticing = true;
        _startTime = DateTime.now();
        _currentSessionId = id;
      });
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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
            const Text(
              '初心者',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // タイマー表示
            StreamBuilder<Duration>(
              stream: _timerStream,
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return Text(
                  _formatDuration(duration),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                );
              },
            ),
            const SizedBox(height: 20),

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
               _navButton(Icons.sports, '試合登録', onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const MatchRegisterScreen(),
                   ),
                 );
               }),
                _navButton(Icons.calendar_month, 'カレンダー', onTap: () {}),
                _navButton(Icons.bar_chart, '分析', onTap: () {}),
                _navButton(Icons.settings, '設定', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _navButton(IconData icon, String label, {required VoidCallback onTap}) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 32),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}