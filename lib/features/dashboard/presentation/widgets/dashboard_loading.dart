import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────
//  DASHBOARD LOADING  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class DashboardLoading extends StatefulWidget {
  const DashboardLoading({super.key});

  @override
  State<DashboardLoading> createState() => _DashboardLoadingState();
}

class _DashboardLoadingState extends State<DashboardLoading>
    with TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg         = Color(0xFF0A0A0F);
  static const _surface    = Color(0xFF0E0E18);
  static const _goldA      = Color(0xFFD4A843);
  static const _goldB      = Color(0xFFE8C86A);
  static const _goldC      = Color(0xFFB8892E);
  static const _accent     = Color(0xFF6C63FF);
  static const _textMuted  = Color(0xFF3A3A55);
  static const _textSub    = Color(0xFF55556A);

  // ── Controllers ──────────────────────────────
  late AnimationController _ringCtrl;      // outer ring spin
  late AnimationController _pulseCtrl;     // center orb breathe
  late AnimationController _dotsCtrl;      // dot wave
  late AnimationController _shimmerCtrl;   // skeleton shimmer
  late AnimationController _fadeCtrl;      // entrance fade

  // ── Animations ───────────────────────────────
  late Animation<double> _ringRotate;
  late Animation<double> _orbScale;
  late Animation<double> _orbGlow;
  late Animation<double> _shimmer;
  late Animation<double> _fadeIn;

  // Dot delays
  final List<Animation<double>> _dotAnims = [];

  @override
  void initState() {
    super.initState();

    // Outer ring — continuous rotation
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _ringRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.linear),
    );

    // Center orb — breathing
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _orbScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _orbGlow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Dots wave
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    for (int i = 0; i < 3; i++) {
      final start = i * 0.2;
      final end   = start + 0.4;
      _dotAnims.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _dotsCtrl,
            curve: Interval(start, end.clamp(0.0, 1.0),
                curve: Curves.easeInOut),
          ),
        ),
      );
    }

    // Skeleton shimmer
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    // Entrance fade
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    _shimmerCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Skeleton card ───────────────────────────
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
              colors: [
                _surface,
                const Color(0xFF1A1A28),
                const Color(0xFF1E1E30),
                _surface,
              ],
              transform: _SlidingGradient(_shimmer.value),
            ),
          ),
        );
      },
    );
  }

  // ─── Gold dots ───────────────────────────────
  Widget _loadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _dotAnims[i],
          builder: (_, __) {
            final t = _dotAnims[i].value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 5,
              height: 5 + t * 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Color.lerp(
                  _goldC.withOpacity(0.3),
                  _goldA,
                  t,
                ),
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

  // ─── Spinning arc ring ────────────────────────
  Widget _spinningRing() {
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

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        color: _bg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ── Central Loader Orb ───────────────────
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // Outer ambient glow
                  AnimatedBuilder(
                    animation: _orbGlow,
                    builder: (_, __) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _goldA.withOpacity(_orbGlow.value * 0.12),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: _accent.withOpacity(_orbGlow.value * 0.08),
                            blurRadius: 60,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Spinning arc ring
                  _spinningRing(),

                  // Center breathing orb
                  AnimatedBuilder(
                    animation: _orbScale,
                    builder: (_, __) => Transform.scale(
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
                              color: _goldA.withOpacity(
                                  _orbGlow.value * 0.7),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Specular shine
                  Positioned(
                    top: 26,
                    left: 31,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Loading Dots ─────────────────────────
            _loadingDots(),

            const SizedBox(height: 10),

            // ── Label ────────────────────────────────
            Text(
              "Loading",
              style: TextStyle(
                color: _textSub,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.5,
              ),
            ),

            const SizedBox(height: 48),

            // ── Skeleton Cards ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [

                  // Top row — 3 profile card skeletons
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
                      Expanded(flex: 2, child: _skeletonCard(
                          width: double.infinity, height: 110)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Arc Ring Painter
// ─────────────────────────────────────────────

class _ArcRingPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;

  const _ArcRingPainter({required this.colorA, required this.colorB});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Long gold arc
    final paintArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [colorA, colorA.withOpacity(0.0)],
        stops: const [0.0, 0.7],
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 1.4, false, paintArc);

    // Short accent arc (offset)
    final paintAccent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
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
//  Sliding Gradient Transform (shimmer)
// ─────────────────────────────────────────────

class _SlidingGradient extends GradientTransform {
  final double slideX;
  const _SlidingGradient(this.slideX);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slideX, 0, 0);
  }
}
