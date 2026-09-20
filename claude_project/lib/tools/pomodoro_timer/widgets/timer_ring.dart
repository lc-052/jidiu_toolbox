import 'dart:math' as math;
import 'package:flutter/material.dart';

class TimerRing extends StatelessWidget {
  final double progress; // 0..1
  final String timeDisplay;
  final bool isRest;
  final double size;

  const TimerRing({
    super.key,
    required this.progress,
    required this.timeDisplay,
    this.isRest = false,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress: 0, strokeWidth: 12, color: Colors.grey.shade300),
          ),
          // Progress ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              strokeWidth: 12,
              color: isRest ? Colors.green.shade400 : Theme.of(context).colorScheme.primary,
            ),
          ),
          // Time text
          Text(
            timeDisplay,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  letterSpacing: -2,
                ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _RingPainter({required this.progress, required this.strokeWidth, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => progress != oldDelegate.progress;
}
