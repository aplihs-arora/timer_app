// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Timer App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const TimerHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key, required this.title});
  final String title;

  @override
  State<TimerHomePage> createState() => _MyTimerHomePageState();
}

class _MyTimerHomePageState extends State<TimerHomePage> {
  Duration _totalDuration = const Duration(hours: 1);
  Duration _intervalDuration = const Duration(seconds: 30);
  Timer? _timer;
  int _intervalsPassed = 0;

  final TextEditingController _totalTimeController = TextEditingController();
  final TextEditingController _intervalTimeController = TextEditingController();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      var initializationSettingsAndroid =
          AndroidInitializationSettings('app_icon');
      var initializationSettingsDarwin = DarwinInitializationSettings();
      var initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin);
      flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveBackgroundNotificationResponse:
              (NotificationResponse response) async {
        if (response.payload != null) {
          debugPrint('notification payload: ${response.payload}');
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    setState(() {
      _intervalsPassed = 0;
    });

    int totalSeconds = _totalDuration.inSeconds;
    int intervalSeconds = _intervalDuration.inSeconds;

    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      setState(() {
        _intervalsPassed++;
      });

      if (kIsWeb) {
        _showWebNotification();
      } else {
        _showMobileNotification();
      }

      if (_intervalsPassed * intervalSeconds >= totalSeconds) {
        _timer?.cancel();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _intervalsPassed = 0;
    });
  }

  void _setTotalDuration() {
    final totalMinutes = int.tryParse(_totalTimeController.text) ?? 60;
    setState(() {
      _totalDuration = Duration(minutes: totalMinutes);
    });
  }

  void _setIntervalDuration() {
    final intervalSeconds = int.tryParse(_intervalTimeController.text) ?? 30;
    setState(() {
      _intervalDuration = Duration(seconds: intervalSeconds);
    });
  }

  Future<void> _showMobileNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'interval_channel', 'Interval Notifications',
        channelDescription: 'Notification channel for interval notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'app_icon',
        ticker: 'ticker');
    var darwinPlatformChannelSpecifics = DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: darwinPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Interval Passed',
      '${_intervalDuration.inSeconds} seconds have passed.',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  void _showWebNotification() {
    if (html.Notification.permission != 'granted') {
      html.Notification.requestPermission().then((permission) {
        if (permission == 'granted') {
          print('Creating web notification --');
          html.Notification('Interval Passed',
              body: '${_intervalDuration.inSeconds} seconds have passed.');
        }
      });
    } else {
      print('Creating web notification');

      html.Notification('Interval Passed',
          body: '${_intervalDuration.inSeconds} seconds have passed.');
    }
  }

  @override
  void dispose() {
    _totalTimeController.dispose();
    _intervalTimeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _totalTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Time (minutes)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _setTotalDuration(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _intervalTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interval Time (seconds)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _setIntervalDuration(),
              ),
              const SizedBox(height: 16),
              Text(
                "Total time : ${_totalDuration.inHours}h ${_totalDuration.inMinutes % 60}m",
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Text(
                "Interval : ${_intervalDuration.inMinutes}m ${_intervalDuration.inSeconds % 60}s",
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'Intervals Passed : $_intervalsPassed',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: _startTimer, child: const Text("Start Timer")),
                  const SizedBox(
                    width: 16,
                  ),
                  ElevatedButton(
                      onPressed: _stopTimer, child: const Text('Stop Timer'))
                ],
              )
            ],
          ),
        ));
  }
}
