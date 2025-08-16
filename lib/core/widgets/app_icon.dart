import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;

class AppIcon extends StatelessWidget {
  final double size;
  final bool showGlow;

  const AppIcon({
    super.key,
    this.size = 1024,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B2B2B),
            Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          if (showGlow)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.15),
                    blurRadius: size * 0.2,
                    spreadRadius: size * 0.05,
                  ),
                ],
              ),
            ),

          // Main gradient circle
          Container(
            width: size * 0.75,
            height: size * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF4A90E2),
                  Color(0xFF2C5282),
                ],
                stops: [0.4, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                  blurRadius: size * 0.1,
                  spreadRadius: size * 0.02,
                ),
              ],
            ),
          ),

          // Inner circle with gradient
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.05),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          // Decorative rings
          ...List.generate(2, (index) {
            final scale = 0.85 - (index * 0.1);
            return Container(
              width: size * scale,
              height: size * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: size * 0.01,
                ),
              ),
            );
          }),

          // "C" letter with modern style
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -size * 0.02,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: size * 0.02,
                      offset: Offset(0, size * 0.01),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Accent dots
          ...List.generate(3, (index) {
            final angle = (index * 120) * (pi / 180);
            final radius = size * 0.35;
            return Positioned(
              left: size * 0.5 + radius * cos(angle),
              top: size * 0.5 + radius * sin(angle),
              child: Container(
                width: size * 0.06,
                height: size * 0.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: showGlow
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: size * 0.02,
                            spreadRadius: size * 0.005,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
