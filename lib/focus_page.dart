import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => FocusPageState();
}

class FocusPageState extends State<FocusPage> with TickerProviderStateMixin {
  int _remainingTime = 1500; // 25分钟，单位为秒
  Timer? _timer;
  late Ticker _ticker;
  bool _isRunning = false;
  int _workDuration = 25; // 默认工作时长，单位为分钟
  int _restDuration = 5; // 默认休息时长，单位为分钟
  late fln.FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  // 添加专注和休息时间的选项
  final List<int> _focusOptions = [25, 35, 45];
  final List<int> _restOptions = [5, 15];

  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _moveAnimationController;
  late Animation<double> _moveAnimation;
  late AnimationController _waveAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  bool _isResting = false; // New variable to track rest/work state

  @override
  void initState() {
    super.initState();
    _localNotificationsPlugin = fln.FlutterLocalNotificationsPlugin();
    const android = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = fln.DarwinInitializationSettings();
    const initSettings = fln.InitializationSettings(android: android, iOS: iOS);
    _localNotificationsPlugin.initialize(initSettings);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _moveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _moveAnimationController,
      curve: Curves.easeInOut,
    ));
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 1000), // Reduced duration for faster movement
    )..repeat();
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _ticker = createTicker((elapsed) {
      setState(() {
        // 这里只触发重绘，不更新 _remainingTime
      });
    });
  }

  void _startPauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _ticker.stop();
      _waveAnimationController.stop();
      _fadeAnimationController.reverse(); // 淡出效果
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _stopTimers();
            _showNotification();
            _startRestTimer();
          }
        });
      });
      _ticker.start();
      _waveAnimationController.repeat();
      _fadeAnimationController.forward(); // 淡入效果
    }
    setState(() {
      _isRunning = !_isRunning;
      _isResting = false; // 设置为工作模式
      if (_isRunning) {
        _animationController.forward();
        _moveAnimationController.forward();
      } else {
        _animationController.reverse();
        _moveAnimationController.reverse();
      }
    });
  }

  void _startRestTimer() {
    setState(() {
      _remainingTime = _restDuration * 60;
      _isRunning = true;
      _isResting = true;
    });
    _waveAnimationController.repeat();
    _ticker.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _stopTimers();
          _showNotification();
        }
      });
    });
  }

  void _stopTimers() {
    _timer?.cancel();
    _ticker.stop();
    _isRunning = false;
    _waveAnimationController.stop();
  }

  void _resetTimer() {
    _stopTimers();
    _fadeAnimationController.reverse(); // 淡出效果
    setState(() {
      _remainingTime = _workDuration * 60;
      _isRunning = false;
      _animationController.reverse();
      _moveAnimationController.reverse();
    });
  }

  Widget _buildAnimatedButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: CustomCurve(), // 使用自定义曲线
      width: 80,
      height: _isRunning ? 48 : 80,
      child: GestureDetector(
        onTap: _startPauseTimer,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary, // 修改为 primary 颜色
            borderRadius:
                BorderRadius.circular(_isRunning ? 24 : 25), // 调整圆角以适应新的高度
          ),
          child: Icon(
            _isRunning ? Icons.pause : Icons.play_arrow,
            size: 30,
            color:
                Theme.of(context).colorScheme.onPrimary, // 修改为 onPrimary 以确保对比度
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _resetTimer,
      color: Theme.of(context).colorScheme.primary, // 修改为 primary 颜色
    );
  }

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
                    // Background container (always present)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Wave animation
                    ClipOval(
                      child: AnimatedBuilder(
                        animation: _waveAnimationController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: WavePainter(
                              animation: _waveAnimationController,
                              isRunning: _isRunning,
                              colorScheme: Theme.of(context).colorScheme,
                              progress: _isRunning
                                  ? 1 -
                                      (_remainingTime /
                                          (_isResting
                                              ? _restDuration * 60
                                              : _workDuration * 60))
                                  : 0,
                              fadeAnimation: _fadeAnimation, // 添加淡入淡出动画
                            ),
                            child: SizedBox(
                              width: 200,
                              height: 200,
                            ),
                          );
                        },
                      ),
                    ),
                    // Timer text
                    AnimatedBuilder(
                      animation: _moveAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _moveAnimation.value * 220), // 位移距离
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(_remainingTime),
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: ColorTween(
                                        begin: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        end: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ).evaluate(_moveAnimation),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRunning ? "专注中" : "准备开始",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: ColorTween(
                                        begin: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        end: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ).evaluate(_moveAnimation),
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  AnimatedOpacity(
                    opacity: _isRunning ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: _isRunning,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              _buildDurationSelector(
                                  '工作时长 (分钟)', _focusOptions, _workDuration,
                                  (newSelection) {
                                setState(() {
                                  _workDuration = newSelection.first;
                                  if (!_isRunning) {
                                    _remainingTime = _workDuration * 60;
                                  }
                                });
                              }),
                              const SizedBox(width: 16),
                              _buildDurationSelector(
                                  '休息时长 (分钟)', _restOptions, _restDuration,
                                  (newSelection) {
                                setState(() {
                                  _restDuration = newSelection.first;
                                });
                              }),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80, // 为按钮预留足够的空间
                    child: Center(
                      child: _buildAnimatedButton(),
                    ),
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
    _stopTimers();
    _ticker.dispose();
    _waveAnimationController.dispose();
    _animationController.dispose();
    _moveAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildDurationSelector(String title, List<int> options,
      int selectedValue, Function(Set<int>) onSelectionChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: options.map((int value) {
            return ButtonSegment<int>(
              value: value,
              label: Text(value.toString()),
            );
          }).toList(),
          selected: {selectedValue},
          onSelectionChanged: onSelectionChanged,
        ),
      ],
    );
  }

  Future<void> _showNotification() async {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
      'focus_timer_channel',
      'Focus Timer Notifications',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      showWhen: false,
    );
    const fln.NotificationDetails platformChannelSpecifics =
        fln.NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotificationsPlugin.show(
      0,
      'Focus Timer',
      _isRunning
          ? 'Time to take a break!'
          : 'Break time is over. Ready to focus?',
      platformChannelSpecifics,
    );
  }
}

class CustomCurve extends Curve {
  @override
  double transform(double t) {
    // This is where you define your custom curve
    // t goes from 0.0 to 1.0
    // Return a value from 0.0 to 1.0
    return t * t; // This creates a quadratic curve
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final bool isRunning;
  final ColorScheme colorScheme;
  final double progress;
  final Animation<double> fadeAnimation;

  WavePainter({
    required this.animation,
    required this.isRunning,
    required this.colorScheme,
    required this.progress,
    required this.fadeAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = fadeAnimation.value;
    if (opacity == 0) return;

    final startHeight = size.height * 0.95;
    final y = startHeight - (startHeight * progress);

    final clipPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ));

    canvas.clipPath(clipPath);

    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final wave1 = _buildWavePath(size, now, 1.5, y);
    final wave2 = _buildWavePath(size, now + 0.5, 1.0, y);

    final paint1 = Paint()
      ..color = colorScheme.primaryContainer.withOpacity(0.7 * opacity);
    final paint2 = Paint()
      ..color = colorScheme.secondaryContainer.withOpacity(0.5 * opacity);

    canvas.drawPath(wave2, paint2);
    canvas.drawPath(wave1, paint1);
  }

  Path _buildWavePath(Size size, double time, double waveHeight, double y) {
    final path = Path();
    path.moveTo(0, y);
    for (var i = 0.0; i <= size.width; i++) {
      path.lineTo(
        i,
        y +
            math.sin((i / size.width * 4 * math.pi) + (time * 2 * math.pi)) *
                waveHeight *
                10,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return true; // 始终重绘以确保流畅的动画
  }
}
