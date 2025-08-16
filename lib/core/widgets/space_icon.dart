import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' show cos, sin;

class SpaceIcon extends StatelessWidget {
  final double size;
  final bool showGlow;

  const SpaceIcon({
    super.key,
    this.size = 1024,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: SpaceIconPainter(showGlow: showGlow),
    );
  }
}

class SpaceIconPainter extends CustomPainter {
  final bool showGlow;

  SpaceIconPainter({this.showGlow = true});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Draw background
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    if (showGlow) {
      // Draw glow
      final glowPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(center, radius * 1.2, glowPaint);
    }

    // Draw planet
    final planetPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.blue.shade400,
          Colors.blue.shade900,
        ],
      );
    canvas.drawCircle(center, radius, planetPaint);

    // Draw stars
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final angle = (i * 72) * (3.14159 / 180);
      final starRadius = radius * 0.8;
      final starX = center.dx + starRadius * cos(angle);
      final starY = center.dy + starRadius * sin(angle);

      // Draw star glow
      if (showGlow) {
        final starGlowPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(Offset(starX, starY), 4, starGlowPaint);
      }

      // Draw star
      canvas.drawCircle(Offset(starX, starY), 2, starPaint);
    }

    // Draw orbit
    final orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.8, orbitPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
