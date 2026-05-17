import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────
//  PROFILE LOADING  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileLoading extends StatefulWidget {
  const ProfileLoading({super.key});

  @override
  State<ProfileLoading> createState() => _ProfileLoadingState();
}

class _ProfileLoadingState extends State<ProfileLoading>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg      = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF0E0E18);
  static const _goldA   = Color(0xFFD4A843);
  static const _goldB   = Color(0xFFE8C86A);
  static const _goldC   = Color(0xFFB8892E);
  static const _accent  = Color(0xFF6C63FF);
  static const _border  = Color(0xFF1E1E2E);
  static const _textSub = Color(0xFF55556A);

  // ⚡ Single controller — all animations
  late AnimationController _ctrl;

  late Animation<double> _ringRotate;
  late Animation<double> _orbScale;
  late Animation<double> _shimmer;
  late Animation<double> _dot0;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Ring rotation
    _ringRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );

    // Orb breathe
    _orbScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Shimmer sweep
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // Staggered dots
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

    // Entrance fade
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Skeleton row ──────────────────────────────
  Widget _skeletonBox({
    required double width,
    required double height,
    double radius = 12,
  }) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Container(
          width:  width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end:   Alignment.centerRight,
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

  // ── Wave dots ─────────────────────────────────
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
              width:  5,
              height: 5 + t * 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Color.lerp(_goldC.withOpacity(0.3), _goldA, t),
                boxShadow: [
                  BoxShadow(
                    color:       _goldA.withOpacity(t * 0.6),
                    blurRadius:  8,
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
      builder: (_, __) => Transform.rotate(
        angle: _ringRotate.value,
        child: CustomPaint(
          size: const Size(72, 72),
          painter: _ArcRingPainter(
            colorA: _goldA,
            colorB: _accent,
          ),
        ),
      ),
    );
  }

  // ── Breathing orb ─────────────────────────────
  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: _orbScale,
      builder: (_, __) => Transform.scale(
        scale: _orbScale.value,
        child: Container(
          width:  36,
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
                color:       _goldA.withOpacity(0.6),
                blurRadius:  16,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _fadeIn,
        builder: (_, child) => Opacity(
          opacity: _fadeIn.value,
          child: child,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [

                // ── Top padding ───────────────────
                const SizedBox(height: 60),

                // ── Central loader orb ────────────
                SizedBox(
                  width:  80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // Ambient glow
                      Container(
                        width:  80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:       _goldA.withOpacity(0.10),
                              blurRadius:  40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color:       _accent.withOpacity(0.06),
                              blurRadius:  60,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                      ),

                      // Spinning arc
                      _buildRing(),

                      // Breathing orb
                      _buildOrb(),

                      // Specular
                      const Positioned(
                        top:  26,
                        left: 31,
                        child: _Specular(),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Wave dots ─────────────────────
                _buildDots(),

                const SizedBox(height: 10),

                // ── Label ─────────────────────────
                const Text(
                  "LOADING PROFILE",
                  style: TextStyle(
                    color:         _textSub,
                    fontSize:      11,
                    fontWeight:    FontWeight.w500,
                    letterSpacing: 2.8,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Skeleton profile layout ────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [

                      // Avatar skeleton (circle)
                      Container(
                        width:  110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: const [
                              _surface,
                              Color(0xFF1A1A28),
                              _surface,
                            ],
                            transform: _SlidingGradient(_shimmer.value),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Name skeleton
                      AnimatedBuilder(
                        animation: _shimmer,
                        builder: (_, __) => _skeletonBox(
                          width:  140,
                          height: 18,
                          radius: 8,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Username skeleton
                      _skeletonBox(
                        width:  90,
                        height: 13,
                        radius: 6,
                      ),

                      const SizedBox(height: 28),

                      // Stats row skeleton
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _skeletonBox(
                            width:  100,
                            height: 56,
                            radius: 14,
                          ),
                          const SizedBox(width: 12),
                          _skeletonBox(
                            width:  100,
                            height: 56,
                            radius: 14,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Divider skeleton
                      _skeletonBox(
                        width:  double.infinity,
                        height: 1,
                        radius: 1,
                      ),

                      const SizedBox(height: 24),

                      // Buttons row skeleton
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _skeletonBox(
                              width:  double.infinity,
                              height: 52,
                              radius: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _skeletonBox(
                              width:  double.infinity,
                              height: 52,
                              radius: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // XP card skeleton
                      _skeletonBox(
                        width:  double.infinity,
                        height: 90,
                        radius: 18,
                      ),

                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );

    // ================= UI END =================
  }
}

// ─────────────────────────────────────────────
//  Specular — static widget
// ─────────────────────────────────────────────

class _Specular extends StatelessWidget {
  const _Specular();

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.6),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Arc Ring Painter
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

    final paintGold = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors: [colorA, colorA.withOpacity(0.0)],
        stops:  const [0.0, 0.7],
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 1.4, false, paintGold);

    final paintAccent = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors:     [colorB, colorB.withOpacity(0.0)],
        stops:      const [0.0, 0.5],
        startAngle: math.pi,
      ).createShader(rect);

    canvas.drawArc(rect, math.pi, math.pi * 0.8, false, paintAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────
//  Sliding Gradient — shimmer transform
// ─────────────────────────────────────────────

class _SlidingGradient extends GradientTransform {
  final double slideX;
  const _SlidingGradient(this.slideX);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slideX, 0, 0);
  }
}
