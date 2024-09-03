import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => FocusPageState();
}

class FocusPageState extends State<FocusPage> with TickerProviderStateMixin {
  int _remainingTime = 1500; // 25分钟，单位为秒
  Timer? _timer;
  bool _isRunning = false;
  int _workDuration = 25; // 默认工作时长，单位为分钟
  int _restDuration = 5; // 默认休息时长，单位为分钟
  late FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  // 添加专注和休息时间的选项
  final List<int> _focusOptions = [25, 35, 45];
  final List<int> _restOptions = [5, 15];

  @override
  void initState() {
    super.initState();
    _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: iOS);
    _localNotificationsPlugin.initialize(initSettings);
  }

  void _startPauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _timer?.cancel();
            _isRunning = false;
            _showNotification();
            _startRestTimer();
          }
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _startRestTimer() {
    setState(() {
      _remainingTime = _restDuration * 60;
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _showNotification();
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingTime = _workDuration * 60;
      _isRunning = false;
    });
  }

  void _showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'channelId',
      'channelName',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iOSDetails = DarwinNotificationDetails();
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);
    await _localNotificationsPlugin.show(
      0,
      '计时结束',
      '请开始休息或继续工作',
      notificationDetails,
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _timer?.cancel();
            _isRunning = false;
            _showNotification();
            _startRestTimer();
          }
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  bool get isTimerRunning => _isRunning;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _remainingTime / (_workDuration * 60),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      _formatTime(_remainingTime),
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '工作时长 (分钟)',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<int>(
                            segments: _focusOptions.map((int value) {
                              return ButtonSegment<int>(
                                value: value,
                                label: Text(value.toString()),
                              );
                            }).toList(),
                            selected: {_workDuration},
                            onSelectionChanged: (Set<int> newSelection) {
                              setState(() {
                                _workDuration = newSelection.first;
                                if (!_isRunning) {
                                  _remainingTime = _workDuration * 60;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '休息时长 (分钟)',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<int>(
                            segments: _restOptions.map((int value) {
                              return ButtonSegment<int>(
                                value: value,
                                label: Text(value.toString()),
                              );
                            }).toList(),
                            selected: {_restDuration},
                            onSelectionChanged: (Set<int> newSelection) {
                              setState(() {
                                _restDuration = newSelection.first;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GestureDetector(
                        onTap: _startPauseTimer,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            size: 30,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _resetTimer,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(
                            Icons.refresh,
                            size: 30,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
