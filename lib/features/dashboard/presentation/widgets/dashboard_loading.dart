import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────
//  DASHBOARD LOADING  —  Premium Dark VIP Edition
//  (Performance Optimized — UI Unchanged)
// ─────────────────────────────────────────────

class DashboardLoading extends StatefulWidget {
  const DashboardLoading({super.key});

  @override
  State<DashboardLoading> createState() => _DashboardLoadingState();
}

class _DashboardLoadingState extends State<DashboardLoading>
    with SingleTickerProviderStateMixin {

  // ── Palette (static const) ───────────────────
  static const _bg      = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF0E0E18);
  static const _goldA   = Color(0xFFD4A843);
  static const _goldB   = Color(0xFFE8C86A);
  static const _goldC   = Color(0xFFB8892E);
  static const _accent  = Color(0xFF6C63FF);
  static const _textSub = Color(0xFF55556A);

  // ⚡ Ek hi controller — sab animations isi se
  late AnimationController _ctrl;

  late Animation<double> _ringRotate;
  late Animation<double> _orbScale;
  late Animation<double> _dot0;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    // ⚡ Single controller — 2400ms loop
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Ring rotation — full loop
    _ringRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );

    // Orb breathe — 0→1→0 within loop
    _orbScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Dots — staggered intervals
    _dot0 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeInOut),
      ),
    );
    _dot1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.3, curve: Curves.easeInOut),
      ),
    );
    _dot2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.4, curve: Curves.easeInOut),
      ),
    );

    // Shimmer sweep
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Skeleton card ─────────────────────────────
  Widget _skeletonCard({
    required double width,
    required double height,
    double radius = 14,
  }) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.4, 0.6, 1.0],
              colors: const [
                _surface,
                Color(0xFF1A1A28),
                Color(0xFF1E1E30),
                _surface,
              ],
              transform: _SlidingGradient(_shimmer.value),
            ),
          ),
        );
      },
    );
  }

  // ── Gold dots ─────────────────────────────────
  Widget _buildDots() {
    final dots = [_dot0, _dot1, _dot2];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: dots[i],
          builder: (_, __) {
            final t = dots[i].value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 5,
              height: 5 + t * 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Color.lerp(_goldC.withOpacity(0.3), _goldA, t),
                boxShadow: [
                  BoxShadow(
                    color: _goldA.withOpacity(t * 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  // ── Spinning arc ring ─────────────────────────
  Widget _buildRing() {
    return AnimatedBuilder(
      animation: _ringRotate,
      builder: (_, __) {
        return Transform.rotate(
          angle: _ringRotate.value,
          child: CustomPaint(
            size: const Size(72, 72),
            painter: _ArcRingPainter(
              colorA: _goldA,
              colorB: _accent,
            ),
          ),
        );
      },
    );
  }

  // ── Center orb ────────────────────────────────
  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: _orbScale,
      builder: (_, __) {
        return Transform.scale(
          scale: _orbScale.value,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _goldB.withOpacity(0.9),
                  _goldA.withOpacity(0.5),
                  _goldC.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _goldA.withOpacity(0.6),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return Container(
      color: _bg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // ── Central loader orb ─────────────────
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [

                // Ambient glow (static — no animation needed)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _goldA.withOpacity(0.10),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: _accent.withOpacity(0.06),
                        blurRadius: 60,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),

                // Spinning arc ring
                _buildRing(),

                // Breathing orb
                _buildOrb(),

                // Specular shine (static)
                const Positioned(
                  top: 26,
                  left: 31,
                  child: _Specular(),
                ),

              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Wave dots ──────────────────────────
          _buildDots(),

          const SizedBox(height: 10),

          // ── Label ──────────────────────────────
          const Text(
            "LOADING",
            style: TextStyle(
              color: _textSub,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
            ),
          ),

          const SizedBox(height: 48),

          // ── Skeleton cards ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [

                // Top row — 3 profile skeletons
                Row(
                  children: [
                    Expanded(child: _skeletonCard(
                        width: double.infinity, height: 140)),
                    const SizedBox(width: 12),
                    Expanded(child: _skeletonCard(
                        width: double.infinity, height: 140)),
                    const SizedBox(width: 12),
                    Expanded(child: _skeletonCard(
                        width: double.infinity, height: 140)),
                  ],
                ),

                const SizedBox(height: 14),

                // Search bar skeleton
                _skeletonCard(
                    width: double.infinity, height: 52, radius: 16),

                const SizedBox(height: 14),

                // Bottom row
                Row(
                  children: [
                    Expanded(child: _skeletonCard(
                        width: double.infinity, height: 110)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _skeletonCard(
                          width: double.infinity, height: 110),
                    ),
                  ],
                ),

              ],
            ),
          ),

        ],
      ),
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Specular shine — static widget
// ─────────────────────────────────────────────

class _Specular extends StatelessWidget {
  const _Specular();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.6),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Arc Ring Painter — same as before
// ─────────────────────────────────────────────

class _ArcRingPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;

  const _ArcRingPainter({
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Gold arc
    final paintArc = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors: [colorA, colorA.withOpacity(0.0)],
        stops: const [0.0, 0.7],
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 1.4, false, paintArc);

    // Accent arc
    final paintAccent = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors: [colorB, colorB.withOpacity(0.0)],
        stops: const [0.0, 0.5],
        startAngle: math.pi,
      ).createShader(rect);

    canvas.drawArc(rect, math.pi, math.pi * 0.8, false, paintAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────
//  Sliding Gradient Transform — shimmer
// ─────────────────────────────────────────────

class _SlidingGradient extends GradientTransform {
  final double slideX;
  const _SlidingGradient(this.slideX);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slideX, 0, 0);
  }
}
