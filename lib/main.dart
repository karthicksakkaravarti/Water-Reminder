import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_reminder/water_bottle_painter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const SmartReminderApp());
}

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  final IOSInitializationSettings initializationSettingsIOS =
      IOSInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void scheduleReminder(String reminder, TimeOfDay time) async {
  var scheduledNotificationDateTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    time.hour,
    time.minute,
  );

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'reminder_channel_id',
    'Reminder Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.schedule(
    0,
    'Reminder',
    reminder,
    scheduledNotificationDateTime,
    platformChannelSpecifics,
  );
}

class SmartReminderApp extends StatelessWidget {
  const SmartReminderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFF0A1931),
        textTheme: Theme.of(context)
            .textTheme
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const WaterTrackerScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  List<String> _reminders = [];
  TextEditingController _customReminderController = TextEditingController();
  TimeOfDay _reminderTime =
      TimeOfDay(hour: 9, minute: 0); // Default reminder time

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _loadReminderTime();
  }

  void _loadReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminders = prefs.getStringList('reminders') ?? [];
    });
  }

  void _saveReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reminders', _reminders);
  }

  void _loadReminderTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int hour = prefs.getInt('reminderHour') ?? 9;
    int minute = prefs.getInt('reminderMinute') ?? 0;
    setState(() {
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  void _addReminder(String reminder) {
    setState(() {
      _reminders.add(reminder);
    });
    _saveReminders();
    // Schedule notification for the reminder
    scheduleReminder(reminder, _reminderTime);
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
    _saveReminders();
  }

  void _undoReminder() {
    if (_reminders.isNotEmpty) {
      setState(() {
        String lastReminder = _reminders.removeLast();
        _saveReminders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed: $lastReminder'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _reminders.add(lastReminder);
                  _saveReminders();
                });
              },
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({Key? key}) : super(key: key);

  @override
  _WaterTrackerScreenState createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  int currentIntake = 0;
  final int dailyGoal = 2000; // in ml
  List<WaterIntake> intakeHistory = [];

  void addWaterIntake(int amount) {
    setState(() {
      currentIntake += amount;
      intakeHistory.insert(0, WaterIntake(DateTime.now(), amount));
    });
  }

  void undoWaterIntake() {
    if (intakeHistory.isNotEmpty) {
      setState(() {
        WaterIntake lastIntake = intakeHistory.removeAt(0);
        currentIntake -= lastIntake.amount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed: ${lastIntake.amount} ml'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  currentIntake += lastIntake.amount;
                  intakeHistory.insert(0, lastIntake);
                });
              },
            ),
          ),
        );
      });
    }
  }

  void resetWaterIntake() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Water Intake'),
          content: Text(
              'Are you sure you want to reset your water intake for today?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Reset'),
              onPressed: () {
                setState(() {
                  currentIntake = 0;
                  intakeHistory.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Water intake reset for today')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double percentage = currentIntake / dailyGoal;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetWaterIntake,
            tooltip: 'Reset Water Intake',
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF185ADB), Color(0xFF0A1931)],
                        ),
                      ),
                    ),
                    Center(
                      child: CustomPaint(
                        size: Size(200, 250),
                        painter: WaterBottlePainter(percentage: percentage),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    _buildAddWaterSection(),
                    const SizedBox(height: 30),
                    const Text(
                      'Today\'s Intake',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return _buildWaterIntakeItem(intakeHistory[index]);
                },
                childCount: intakeHistory.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: undoWaterIntake,
        child: Icon(Icons.undo),
      ),
    );
  }

  Widget _buildWaterProgress() {
    double percentage = currentIntake / dailyGoal;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF185ADB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF185ADB).withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: WavePainter(percentage: percentage),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  '$currentIntake / $dailyGoal ml',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddWaterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Add',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAddWaterButton(100),
            _buildAddWaterButton(200),
            _buildAddWaterButton(300),
          ],
        ),
        const SizedBox(height: 15),
        Center(
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement custom amount input
            },
            child: const Text('Add Custom Amount'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF185ADB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddWaterButton(int amount) {
    return ElevatedButton(
      onPressed: () => addWaterIntake(amount),
      child: Text('$amount ml'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF185ADB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildWaterIntakeItem(WaterIntake intake) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF185ADB).withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: Color(0xFF185ADB)),
              const SizedBox(width: 10),
              Text(
                '${intake.amount} ml',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          Text(
            DateFormat('HH:mm').format(intake.time),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class WaterIntake {
  final DateTime time;
  final int amount;

  WaterIntake(this.time, this.amount);
}

class WavePainter extends CustomPainter {
  final double percentage;

  WavePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final wave1Paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final wave2Paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final wave1Path = Path();
    final wave2Path = Path();

    final waveHeight = size.height * 0.1;
    final waveCount = 3;
    final waveDistance = size.width / waveCount;

    wave1Path.moveTo(0, size.height);
    wave2Path.moveTo(0, size.height);

    for (int i = 0; i <= waveCount; i++) {
      final x = i * waveDistance;
      final y1 = size.height -
          (size.height * percentage) +
          math.sin(i * 0.5) * waveHeight;
      final y2 = size.height -
          (size.height * percentage) +
          math.cos(i * 0.5) * waveHeight;
      wave1Path.lineTo(x, y1);
      wave2Path.lineTo(x, y2);
    }

    wave1Path.lineTo(size.width, size.height);
    wave2Path.lineTo(size.width, size.height);

    canvas.drawPath(wave1Path, wave1Paint);
    canvas.drawPath(wave2Path, wave2Paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History')),
      body: Center(
        child: Text('History Screen', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _reminderTime = TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadReminderTime();
  }

  void _loadReminderTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int hour = prefs.getInt('reminderHour') ?? 9;
    int minute = prefs.getInt('reminderMinute') ?? 0;
    setState(() {
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  void _saveReminderTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderHour', _reminderTime.hour);
    await prefs.setInt('reminderMinute', _reminderTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Set Reminder Time'),
            subtitle: Text(_reminderTime.format(context)),
            onTap: () async {
              TimeOfDay? newTime = await showTimePicker(
                context: context,
                initialTime: _reminderTime,
              );
              if (newTime != null) {
                setState(() {
                  _reminderTime = newTime;
                });
                _saveReminderTime();
              }
            },
          ),
        ],
      ),
    );
  }
}
