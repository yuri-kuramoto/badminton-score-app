import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'screens/match_register_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbHelper.instance.database;
  final settings = await DbHelper.instance.getSettings();
  final savedColor = settings['theme_color'] as String? ?? '#2196F3';
  runApp(MyApp(initialColor: savedColor));
}

class MyApp extends StatefulWidget {
  final String initialColor;
  const MyApp({super.key, required this.initialColor});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Color themeColor;

  final Map<String, Color> colorMap = {
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

  @override
  void initState() {
    super.initState();
    themeColor = colorMap[widget.initialColor] ?? Colors.blue;
  }

  void updateThemeColor(Color color) {
    setState(() => themeColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ファミバド',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
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
  String _currentTitle = '初心者';

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (_) {
      if (_isPracticing && _startTime != null) {
        return DateTime.now().difference(_startTime!);
      }
      return Duration.zero;
    });
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DbHelper.instance.getSettings();
    setState(() {
      _currentTitle = settings['selected_title'] as String? ?? '初心者';
    });
  }

  void _togglePractice() async {
    if (_isPracticing) {
      await DbHelper.instance.endPractice(_currentSessionId!);
      setState(() {
        _isPracticing = false;
        _elapsed = Duration.zero;
        _currentSessionId = null;
        _startTime = null;
      });
    } else {
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
            Text(
              '🏆 $_currentTitle',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

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

            ElevatedButton(
              onPressed: _togglePractice,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPracticing
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              ),
              child: Text(
                _isPracticing ? '練習終了' : '練習開始',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 40),

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
                _navButton(Icons.calendar_month, 'カレンダー', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                }),
                _navButton(Icons.bar_chart, '分析', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalysisScreen(),
                    ),
                  );
                }),
                _navButton(Icons.settings, '設定', onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  _loadSettings();
                }),
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