import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────
//  DASHBOARD EMPTY  —  Premium Dark VIP Edition
//  (Performance Optimized — UI Unchanged)
// ─────────────────────────────────────────────

class DashboardEmpty extends StatefulWidget {
  const DashboardEmpty({super.key});

  @override
  State<DashboardEmpty> createState() => _DashboardEmptyState();
}

class _DashboardEmptyState extends State<DashboardEmpty>
    with SingleTickerProviderStateMixin {

  // ── Palette (static const) ───────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _accent    = Color(0xFF6C63FF);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textSub   = Color(0xFF55556A);

  // ⚡ Ek hi controller — sab animations isi se
  late AnimationController _ctrl;

  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _iconScale;
  late Animation<double> _floatY;
  late Animation<double> _orbitAngle;

  @override
  void initState() {
    super.initState();

    // ⚡ Single controller 3000ms
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Entrance fade — only first 600ms
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Slide up — only first 700ms
    _slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.23, curve: Curves.easeOutCubic),
      ),
    );

    // Icon elastic scale — first 700ms
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.03, 0.23, curve: Curves.elasticOut),
      ),
    );

    // Float — continuous gentle bob
    _floatY = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Orbit — full rotation per loop
    _orbitAngle = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Particles (static — no animation) ────────
  static const List<_Particle> _particleList = [
    _Particle(dx: -90, dy: -120, size: 2.5),
    _Particle(dx:  80, dy: -100, size: 1.8),
    _Particle(dx: -70, dy:  60,  size: 2.0),
    _Particle(dx:  100, dy: 80,  size: 1.5),
    _Particle(dx: -110, dy: 20,  size: 1.2),
    _Particle(dx:  60,  dy: -60, size: 2.2),
  ];

  Widget _buildParticles() {
    // ⚡ Static particles — no animation controller
    // Float effect comes from parent _floatY naturally
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: _particleList.map((p) {
          return Positioned(
            left: 130 + p.dx,
            top:  130 + p.dy,
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _goldA.withOpacity(0.45),
                boxShadow: [
                  BoxShadow(
                    color: _goldA.withOpacity(0.5),
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
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [

              // Dashed orbit track (static)
              CustomPaint(
                size: const Size(116, 116),
                painter: _DashedCirclePainter(
                  color: _border,
                  dashCount: 28,
                ),
              ),

              // Moving orbit dot
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
  Widget _buildIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _surface,
        border: Border.all(color: _border, width: 1),
        // ⚡ Static glow — no pulse animation
        boxShadow: [
          BoxShadow(
            color: _goldA.withOpacity(0.12),
            blurRadius: 28,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: _accent.withOpacity(0.07),
            blurRadius: 45,
            spreadRadius: 8,
          ),
        ],
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
                // ⚡ child passed — heavy widgets not rebuilt
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // Static particles
                      _buildParticles(),

                      // Orbit ring + moving dot
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

              // ── Title ──────────────────────────
              const Text(
                "No Profiles Found",
                style: TextStyle(
                  color: _textPrime,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 10),

              // ── Subtitle ───────────────────────
              const Text(
                "Try adjusting your filters\nor check back later",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSub,
                  fontSize: 13,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 32),

              // ── Gold divider ───────────────────
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
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Particle Data — simple const class
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
//  Dashed Circle Painter — same as before
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
