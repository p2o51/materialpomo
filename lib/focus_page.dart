import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'focus_todo_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<int> _focusOptions = [25, 35, 45];
  List<int> _restOptions = [5, 15];

  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _moveAnimationController;
  late Animation<double> _moveAnimation;
  late AnimationController _waveAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  bool _isResting = false; // New variable to track rest/work state

  int _loopCount = 0; // Track the current loop count

  // Add these variables to store the preset durations
  List<int> _presetFocusOptions = [25, 35, 45];
  List<int> _presetRestOptions = [5, 15];

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
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

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _presetFocusOptions = prefs
              .getStringList('focusOptions')
              ?.map((e) => int.parse(e))
              .toList() ??
          [25, 35, 45];
      _presetRestOptions = prefs
              .getStringList('restOptions')
              ?.map((e) => int.parse(e))
              .toList() ??
          [5, 15];
      _focusOptions = _presetFocusOptions;
      _restOptions = _presetRestOptions;
    });
  }

  void _startPauseTimer() {
    HapticFeedback.mediumImpact(); // Add haptic feedback
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

          if (_loopCount < 4) {
            // Start a new focus session
            _loopCount++;
            HapticFeedback.mediumImpact(); // Add haptic feedback
            _startPauseTimer();
          } else {
            // End the loop after four sessions
            HapticFeedback.heavyImpact(); // Add haptic feedback
            _showEncouragementPopup();
            _loopCount = 0; // Reset the loop count
          }
        }
      });
    });
  }

  void _stopTimers() {
    HapticFeedback.heavyImpact(); // Add haptic feedback
    _timer?.cancel();
    _ticker.stop();
    _waveAnimationController.stop();
    _fadeAnimationController.reverse();
    setState(() {
      _isRunning = false;
      _isResting = false;
      _remainingTime = _workDuration * 60;
      _animationController.reverse();
      _moveAnimationController.reverse();
      if (_loopCount == 4) {
        _showEncouragementPopup(); // Show encouragement UI after completing 4 focus cycles
      }
      _loopCount = 0; // Reset loop count on stop
    });
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact(); // Add haptic feedback
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

  Widget _buildWorkCounter() {
    return AnimatedBuilder(
      animation: _moveAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _loopCount
                    ? ColorTween(
                        begin: Theme.of(context).colorScheme.onPrimary,
                        end: Theme.of(context).colorScheme.primary,
                      ).evaluate(_moveAnimation)
                    : Colors.transparent,
                border: Border.all(
                  color: ColorTween(
                    begin: Theme.of(context).colorScheme.onPrimary,
                    end: Theme.of(context).colorScheme.primary,
                  ).evaluate(_moveAnimation)!,
                  width: 2,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _showEncouragementPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("专注完成！"),
          content: Text("专注了 ${_workDuration * _loopCount} 分钟"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetTimer();
              },
              child: const Text("结束专注"),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    List<int> tempFocusOptions = List.from(_presetFocusOptions);
    List<int> tempRestOptions = List.from(_presetRestOptions);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置预设时长'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('设置工作时长（分钟）',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16), // 增加上方间距
                Row(
                  children: _buildDurationInputs(tempFocusOptions, 3),
                ),
                const SizedBox(height: 24), // 增加下方间距
                const Divider(),
                const SizedBox(height: 24), // 增加上方间距
                Text('设置休息时长（分钟）',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16), // 增加上方间距
                Row(
                  children: _buildDurationInputs(tempRestOptions, 2),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () async {
                setState(() {
                  _presetFocusOptions = tempFocusOptions;
                  _presetRestOptions = tempRestOptions;
                  _focusOptions = _presetFocusOptions;
                  _restOptions = _presetRestOptions;
                });
                // 保存到持久存储
                final prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('focusOptions',
                    _presetFocusOptions.map((e) => e.toString()).toList());
                await prefs.setStringList('restOptions',
                    _presetRestOptions.map((e) => e.toString()).toList());
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDurationInputs(List<int> options, int count) {
    return List.generate(count, (index) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextFormField(
            initialValue: options[index].toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: '选项 ${index + 1}',
              // 删除了 suffixText: '分钟'
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty) {
                options[index] = int.parse(value);
              }
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FocusTodoProvider>(
          builder: (context, focusTodoProvider, child) {
            return Text(
              focusTodoProvider.focusTodo != null
                  ? "正在专注于：${focusTodoProvider.focusTodo}"
                  : (_isRunning || _remainingTime < _workDuration * 60
                      ? "自由专注中"
                      : "专注"),
              style:
                  Theme.of(context).textTheme.titleLarge, // Updated this line
            );
          },
        ),
        titleSpacing: 16,
        actions: [
          // Stop button
          IconButton.filled(
            onPressed: (_isRunning || _remainingTime < _workDuration * 60)
                ? () {
                    HapticFeedback.heavyImpact();
                    _stopTimers();
                  }
                : null,
            icon: const Icon(Icons.stop_outlined),
            style: IconButton.styleFrom(
              backgroundColor:
                  (_isRunning || _remainingTime < _workDuration * 60)
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(width: 8), // Add some spacing between buttons
          // New settings button
          IconButton.outlined(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings_outlined),
            style: IconButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 16), // Add some padding to the right
        ],
        elevation: 0,
      ),
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
                              fadeAnimation: _fadeAnimation, // 添加淡入淡动画
                            ),
                            child: const SizedBox(
                              width: 200,
                              height: 200,
                            ),
                          );
                        },
                      ),
                    ),
                    // Timer text, status, and work counter
                    AnimatedBuilder(
                      animation: _moveAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _moveAnimation.value * 220),
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
                              _buildWorkCounter(), // Work counter is now always visible
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
                    height: 80, // 为按钮预留足够的空
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
          onSelectionChanged: (Set<int> newSelection) {
            HapticFeedback.selectionClick(); // Add haptic feedback
            onSelectionChanged(newSelection);
          },
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
