import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────
//  DASHBOARD EMPTY  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class DashboardEmpty extends StatefulWidget {
  const DashboardEmpty({super.key});

  @override
  State<DashboardEmpty> createState() => _DashboardEmptyState();
}

class _DashboardEmptyState extends State<DashboardEmpty>
    with TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _accent    = Color(0xFF6C63FF);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF3A3A55);
  static const _textSub   = Color(0xFF55556A);

  // ── Controllers ──────────────────────────────
  late AnimationController _entranceCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _orbitCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _particleCtrl;

  // ── Animations ───────────────────────────────
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _iconScale;
  late Animation<double> _floatY;
  late Animation<double> _orbitAngle;
  late Animation<double> _glowPulse;
  late Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();

    // Entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Floating idle
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatY = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Orbit ring
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    _orbitAngle = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _orbitCtrl, curve: Curves.linear),
    );

    // Glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Particles drift
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _particleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleCtrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    _orbitCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  // ── Floating particles ────────────────────────
  static const _particles = [
    _Particle(dx: -90, dy: -120, size: 2.5, speed: 0.0),
    _Particle(dx:  80, dy: -100, size: 1.8, speed: 0.2),
    _Particle(dx: -70, dy:  60,  size: 2.0, speed: 0.4),
    _Particle(dx:  100, dy: 80,  size: 1.5, speed: 0.6),
    _Particle(dx: -110, dy: 20,  size: 1.2, speed: 0.15),
    _Particle(dx:  60,  dy: -60, size: 2.2, speed: 0.75),
  ];

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleAnim,
      builder: (_, __) {
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: _particles.map((p) {
              final t = (_particleAnim.value + p.speed) % 1.0;
              final floatOffset = math.sin(t * 2 * math.pi) * 8;
              return Positioned(
                left: 130 + p.dx.toDouble(),
                top: 130 + p.dy.toDouble() + floatOffset.toDouble(),
                child: Opacity(
                  opacity: (0.3 + math.sin(t * math.pi) * 0.5).clamp(0.0, 1.0),
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _goldA,
                      boxShadow: [
                        BoxShadow(
                          color: _goldA.withOpacity(0.6),
                          blurRadius: p.size * 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Orbiting dot ─────────────────────────────
  Widget _orbitDot() {
    return AnimatedBuilder(
      animation: _orbitAngle,
      builder: (_, __) {
        const orbitR = 58.0;
        final x = math.cos(_orbitAngle.value) * orbitR;
        final y = math.sin(_orbitAngle.value) * orbitR;
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dashed orbit track
              CustomPaint(
                size: const Size(116, 116),
                painter: _DashedCirclePainter(
                  color: _border,
                  dashCount: 28,
                ),
              ),
              // Moving dot
              Transform.translate(
                offset: Offset(x, y),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _goldA,
                    boxShadow: [
                      BoxShadow(
                        color: _goldA.withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Center icon ───────────────────────────────
  Widget _centerIcon() {
    return AnimatedBuilder(
      animation: _glowPulse,
      builder: (_, child) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _surface,
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: _goldA.withOpacity(_glowPulse.value * 0.15),
              blurRadius: 30,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: _accent.withOpacity(_glowPulse.value * 0.08),
              blurRadius: 50,
              spreadRadius: 8,
            ),
          ],
        ),
        child: child,
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [_goldA, _goldB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: const Icon(
          Icons.person_search_rounded,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return Container(
      color: _bg,
      child: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: AnimatedBuilder(
            animation: _slideUp,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: child,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Floating Icon Assembly ───────────
                AnimatedBuilder(
                  animation: _floatY,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _floatY.value),
                    child: child,
                  ),
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Drifting gold particles
                        _buildParticles(),

                        // Outer orbit ring + dot
                        _orbitDot(),

                        // Scale-in center icon
                        AnimatedBuilder(
                          animation: _iconScale,
                          builder: (_, child) => Transform.scale(
                            scale: _iconScale.value,
                            child: child,
                          ),
                          child: _centerIcon(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Title ─────────────────────────────
                Text(
                  "No Profiles Found",
                  style: const TextStyle(
                    color: _textPrime,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),

                const SizedBox(height: 10),

                // ── Subtitle ──────────────────────────
                Text(
                  "Try adjusting your filters\nor check back later",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textSub,
                    fontSize: 13,
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Gold divider ──────────────────────
                Container(
                  width: 40,
                  height: 1.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        _goldA,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Particle Data
// ─────────────────────────────────────────────

class _Particle {
  final double dx;
  final double dy;
  final double size;
  final double speed;
  const _Particle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.speed,
  });
}

// ─────────────────────────────────────────────
//  Dashed Circle Painter
// ─────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color  color;
  final int    dashCount;

  const _DashedCirclePainter({
    required this.color,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..style       = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final step   = (2 * math.pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final angle = i * step;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 1.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
