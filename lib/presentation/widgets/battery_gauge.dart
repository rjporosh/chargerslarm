import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Large circular gauge showing current battery percentage against the
/// configured target, with a distinct color once charging and a celebratory
/// tone once the target is reached. This is the dashboard's visual anchor,
/// so it is deliberately the most polished widget in the app.
class BatteryGauge extends StatelessWidget {
  const BatteryGauge({
    super.key,
    required this.percentage,
    required this.targetPercentage,
    required this.isCharging,
    required this.targetReached,
    this.size = 220,
  });

  final int percentage;
  final int targetPercentage;
  final bool isCharging;
  final bool targetReached;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progressColor = targetReached ? Colors.greenAccent.shade400 : scheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percentage / 100),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _GaugePainter(
              progress: value,
              targetFraction: targetPercentage / 100,
              trackColor: scheme.surfaceContainerHighest,
              progressColor: progressColor,
              targetMarkerColor: scheme.tertiary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCharging)
                    Icon(Icons.bolt_rounded, color: progressColor, size: size * 0.14),
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Target $targetPercentage%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.targetFraction,
    required this.trackColor,
    required this.progressColor,
    required this.targetMarkerColor,
  });

  final double progress;
  final double targetFraction;
  final Color trackColor;
  final Color progressColor;
  final Color targetMarkerColor;

  static const _startAngle = -math.pi / 2;
  static const _strokeWidth = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      sweep,
      false,
      progressPaint,
    );

    // Target marker: a short tick at the target fraction around the ring.
    final targetAngle = _startAngle + 2 * math.pi * targetFraction.clamp(0.0, 1.0);
    final markerOuter = center +
        Offset(math.cos(targetAngle), math.sin(targetAngle)) * (radius + _strokeWidth / 2 + 4);
    final markerInner = center +
        Offset(math.cos(targetAngle), math.sin(targetAngle)) * (radius - _strokeWidth / 2 - 4);
    final markerPaint = Paint()
      ..color = targetMarkerColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(markerInner, markerOuter, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.targetFraction != targetFraction ||
        oldDelegate.progressColor != progressColor;
  }
}
