import 'dart:math';
import 'package:flutter/material.dart';

class GalaxyBackground extends StatelessWidget {
  final Widget child;

  const GalaxyBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // 🔥 BASE DARK GRADIENT
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D001A),
                Color(0xFF000000),
                Color(0xFF001A1F),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 🌌 RADIAL GLOW TOP LEFT
        Positioned(
          top: -120,
          left: -120,
          child: _GlowCircle(
            size: 300,
            colors: const [
              Color(0xFF9C27B0),
              Colors.transparent,
            ],
          ),
        ),

        // 🌌 RADIAL GLOW TOP RIGHT
        Positioned(
          top: -80,
          right: -80,
          child: _GlowCircle(
            size: 250,
            colors: const [
              Color(0xFF00BCD4),
              Colors.transparent,
            ],
          ),
        ),

        // 🌌 RADIAL GLOW BOTTOM
        Positioned(
          bottom: -150,
          left: -100,
          child: _GlowCircle(
            size: 350,
            colors: const [
              Color(0xFFFF00C8),
              Colors.transparent,
            ],
          ),
        ),

        // ✨ SOFT NOISE STARS (Lightweight)
        const _StarField(),

        // 🔹 CONTENT
        child,
      ],
    );
  }
}

// ------------------ GLOW CIRCLE ------------------

class _GlowCircle extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowCircle({
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ------------------ STAR FIELD ------------------

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarPainter(),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Random _random = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 80; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
