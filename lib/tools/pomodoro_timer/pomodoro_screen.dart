import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/hive/hive_init.dart';
import '../../../shared/widgets/common_app_bar.dart';
import 'widgets/timer_ring.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with WidgetsBindingObserver {
  late int _workMinutes;
  late int _restMinutes;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isRest = false; // false = work, true = rest
  int _completedPomodoros = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 从 Hive 加载用户设置的时长
    _workMinutes = AppPreferences.getWorkMinutes();
    _restMinutes = AppPreferences.getRestMinutes();
    _remainingSeconds = _workMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        _complete();
        t.cancel();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _isRest ? _restMinutes * 60 : _workMinutes * 60;
    });
  }

  void _complete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (!_isRest) {
        _completedPomodoros++;
      }
      _switchPhase();
    });

    // Vibrate on completion
    // TODO: vibration plugin, or just leave it

    // Show dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(_isRest ? '休息结束！' : '番茄完成！🍅'),
          content: Text(_isRest ? '继续专注吧！' : '休息一下~'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isRunning = true);
                _timer = Timer.periodic(const Duration(seconds: 1), (t) {
                  if (_remainingSeconds <= 1) {
                    _complete();
                    t.cancel();
                  } else {
                    setState(() => _remainingSeconds--);
                  }
                });
              },
              child: const Text('开始'),
            ),
          ],
        ),
      );
    }
  }

  void _switchPhase() {
    setState(() {
      _isRest = !_isRest;
      _remainingSeconds = _isRest ? _restMinutes * 60 : _workMinutes * 60;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _isRest ? _restMinutes * 60 : _workMinutes * 60;
    final progress = total > 0 ? (_remainingSeconds / total).toDouble() : 0.0;

    return Scaffold(
      appBar: CommonAppBar(
        title: '番茄钟',
        actions: [
          Text(
            '🍅 $_completedPomodoros',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer display
            TimerRing(
              progress: progress,
              timeDisplay: _formatTime(_remainingSeconds),
              isRest: _isRest,
            ),
            const SizedBox(height: 24),

            // Phase label
            Text(
              _isRest ? '休息时间' : '专注时间',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 48),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                _controlButton(
                  icon: Icons.restart_alt,
                  label: '重置',
                  onPressed: _reset,
                ),
                const SizedBox(width: 24),
                // Start/Pause
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _isRunning ? _pause : _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.primary,
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      size: 32,
                      color: _isRunning
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _controlButton({required IconData icon, required String label, required VoidCallback onPressed}) {
  return OutlinedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(label),
      ],
    ),
  );
}
