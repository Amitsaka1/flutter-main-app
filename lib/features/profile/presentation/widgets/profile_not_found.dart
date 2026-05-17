import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────
//  PROFILE NOT FOUND  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileNotFound extends StatefulWidget {
  const ProfileNotFound({super.key});

  @override
  State<ProfileNotFound> createState() => _ProfileNotFoundState();
}

class _ProfileNotFoundState extends State<ProfileNotFound>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _accent    = Color(0xFF6C63FF);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textSub   = Color(0xFF55556A);

  // ⚡ Single controller — all animations
  late AnimationController _ctrl;

  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _iconScale;
  late Animation<double> _floatY;
  late Animation<double> _orbitAngle;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Entrance fade
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
      ),
    );

    // Slide up
    _slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOutCubic),
      ),
    );

    // Icon elastic entrance
    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.03, 0.25, curve: Curves.elasticOut),
      ),
    );

    // Gentle float — continuous
    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Orbit dot — full rotation
    _orbitAngle = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.linear,
      ),
    );

    // Glow breathe
    _glowPulse = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Static particles ──────────────────────────
  static const List<_Particle> _particleList = [
    _Particle(dx: -85,  dy: -110, size: 2.2),
    _Particle(dx:  75,  dy: -95,  size: 1.6),
    _Particle(dx: -65,  dy:  55,  size: 1.9),
    _Particle(dx:  95,  dy:  75,  size: 1.4),
    _Particle(dx: -100, dy:  18,  size: 1.1),
    _Particle(dx:  55,  dy: -55,  size: 2.0),
  ];

  Widget _buildParticles() {
    return SizedBox(
      width:  260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: _particleList.map((p) {
          return Positioned(
            left: 130 + p.dx,
            top:  130 + p.dy,
            child: Container(
              width:  p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _goldA.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color:      _goldA.withOpacity(0.45),
                    blurRadius: p.size * 2,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Orbit ring + dot ──────────────────────────
  Widget _buildOrbit() {
    return AnimatedBuilder(
      animation: _orbitAngle,
      builder: (_, __) {
        const orbitR = 58.0;
        final x = math.cos(_orbitAngle.value) * orbitR;
        final y = math.sin(_orbitAngle.value) * orbitR;

        return SizedBox(
          width:  140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [

              // Dashed track
              CustomPaint(
                size: const Size(116, 116),
                painter: _DashedCirclePainter(
                  color:     _border,
                  dashCount: 28,
                ),
              ),

              // Moving dot
              Transform.translate(
                offset: Offset(x, y),
                child: Container(
                  width:  7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent,
                    boxShadow: [
                      BoxShadow(
                        color:       _accent.withOpacity(0.8),
                        blurRadius:  10,
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
  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _glowPulse,
      builder: (_, child) => Container(
        width:  72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _surface,
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color:       _accent.withOpacity(_glowPulse.value * 0.18),
              blurRadius:  30,
              spreadRadius: 4,
            ),
            BoxShadow(
              color:       _goldA.withOpacity(_glowPulse.value * 0.08),
              blurRadius:  50,
              spreadRadius: 8,
            ),
          ],
        ),
        child: child,
      ),
      child: ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [_goldA, _goldB],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ).createShader(b),
        child: const Icon(
          Icons.person_off_rounded,
          size:  32,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            return Opacity(
              opacity: _fadeIn.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, _slideUp.value),
                child: child,
              ),
            );
          },

          // ⚡ child passed — not rebuilt every frame
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Floating icon assembly ───────────
              AnimatedBuilder(
                animation: _floatY,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _floatY.value),
                  child: child,
                ),
                child: SizedBox(
                  width:  260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // Static gold particles
                      _buildParticles(),

                      // Orbit ring + accent dot
                      _buildOrbit(),

                      // Icon with elastic entrance
                      AnimatedBuilder(
                        animation: _iconScale,
                        builder: (_, child) => Transform.scale(
                          scale: _iconScale.value,
                          child: child,
                        ),
                        child: _buildIcon(),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ── Title ────────────────────────────
              const Text(
                "Profile Not Found",
                style: TextStyle(
                  color:         _textPrime,
                  fontSize:      20,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 10),

              // ── Subtitle ─────────────────────────
              const Text(
                "This profile may have been\nremoved or doesn't exist",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:    _textSub,
                  fontSize: 13,
                  height:   1.6,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 32),

              // ── Gold divider ─────────────────────
              Container(
                width:  40,
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
    );

    // ================= UI END =================
  }
}

// ─────────────────────────────────────────────
//  Particle Data
// ─────────────────────────────────────────────

class _Particle {
  final double dx;
  final double dy;
  final double size;

  const _Particle({
    required this.dx,
    required this.dy,
    required this.size,
  });
}

// ─────────────────────────────────────────────
//  Dashed Circle Painter
// ─────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int   dashCount;

  const _DashedCirclePainter({
    required this.color,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint  = Paint()..color = color..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final step   = (2 * math.pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final angle = i * step;
      canvas.drawCircle(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        1.4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
