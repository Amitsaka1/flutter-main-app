import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────
//  CHAT LIST EMPTY  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ChatListEmpty extends StatefulWidget {
  final bool loading;

  const ChatListEmpty({
    super.key,
    required this.loading,
  });

  @override
  State<ChatListEmpty> createState() => _ChatListEmptyState();
}

class _ChatListEmptyState extends State<ChatListEmpty>
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

  // ── Loading animations ────────────────────────
  late Animation<double> _ringRotate;
  late Animation<double> _orbScale;
  late Animation<double> _dot0;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _shimmer;

  // ── Empty animations ─────────────────────────
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
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // ── Loading ───────────────────────────────
    _ringRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );

    _orbScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

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

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // ── Empty ─────────────────────────────────
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOutCubic),
      ),
    );

    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.03, 0.25, curve: Curves.elasticOut),
      ),
    );

    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _orbitAngle = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );

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

  // ─────────────────────────────────────────────
  //  LOADING STATE
  // ─────────────────────────────────────────────

  // ── Skeleton chat row ─────────────────────────
  Widget _skeletonRow({double nameWidth = 120, double msgWidth = 180}) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical:   8,
          ),
          child: Row(
            children: [

              // Avatar skeleton
              Container(
                width:  50,
                height: 50,
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

              const SizedBox(width: 14),

              // Text skeletons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      width:  nameWidth,
                      height: 13,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
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

                    const SizedBox(height: 8),

                    Container(
                      width:  msgWidth,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
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

                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      color: _bg,
      child: Column(
        children: [

          const SizedBox(height: 50),

          // Central loader
          SizedBox(
            width:  80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [

                // Ambient glow
                AnimatedBuilder(
                  animation: _orbScale,
                  builder: (_, __) => Container(
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
                ),

                // Spinning arc ring
                AnimatedBuilder(
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
                ),

                // Breathing orb
                AnimatedBuilder(
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
                ),

                // Specular
                Positioned(
                  top:  26,
                  left: 31,
                  child: Container(
                    width:  7,
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

          const SizedBox(height: 24),

          // Wave dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [_dot0, _dot1, _dot2].map((anim) {
              return AnimatedBuilder(
                animation: anim,
                builder: (_, __) {
                  final t = anim.value;
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
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Label
          const Text(
            "LOADING CHATS",
            style: TextStyle(
              color:         _textSub,
              fontSize:      11,
              fontWeight:    FontWeight.w500,
              letterSpacing: 2.8,
            ),
          ),

          const SizedBox(height: 36),

          // Skeleton rows
          _skeletonRow(nameWidth: 110, msgWidth: 190),
          _skeletonRow(nameWidth: 140, msgWidth: 160),
          _skeletonRow(nameWidth: 90,  msgWidth: 200),
          _skeletonRow(nameWidth: 125, msgWidth: 145),
          _skeletonRow(nameWidth: 100, msgWidth: 175),

        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  EMPTY STATE
  // ─────────────────────────────────────────────

  static const List<_Particle> _particleList = [
    _Particle(dx: -85,  dy: -110, size: 2.2),
    _Particle(dx:  75,  dy: -95,  size: 1.6),
    _Particle(dx: -65,  dy:  55,  size: 1.9),
    _Particle(dx:  95,  dy:  75,  size: 1.4),
    _Particle(dx: -100, dy:  18,  size: 1.1),
    _Particle(dx:  55,  dy: -55,  size: 2.0),
  ];

  Widget _buildEmpty() {
    return Container(
      color: _bg,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(
            opacity: _fadeIn.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: child,
            ),
          ),
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

                      // Static particles
                      SizedBox(
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
                                      color:      _goldA.withOpacity(0.4),
                                      blurRadius: p.size * 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Orbit ring + accent dot
                      AnimatedBuilder(
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
                                CustomPaint(
                                  size: const Size(116, 116),
                                  painter: _DashedCirclePainter(
                                    color:     _border,
                                    dashCount: 28,
                                  ),
                                ),
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
                      ),

                      // Center icon with glow
                      AnimatedBuilder(
                        animation: Listenable.merge([_iconScale, _glowPulse]),
                        builder: (_, child) => Transform.scale(
                          scale: _iconScale.value,
                          child: Container(
                            width:  72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _surface,
                              border: Border.all(color: _border, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color:       _accent.withOpacity(
                                    _glowPulse.value * 0.18,
                                  ),
                                  blurRadius:  30,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color:       _goldA.withOpacity(
                                    _glowPulse.value * 0.08,
                                  ),
                                  blurRadius:  50,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [_goldA, _goldB],
                                begin:  Alignment.topLeft,
                                end:    Alignment.bottomRight,
                              ).createShader(b),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size:  32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Title
              const Text(
                "No Chats Yet",
                style: TextStyle(
                  color:         _textPrime,
                  fontSize:      20,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle
              const Text(
                "Start a conversation by\nvisiting someone's profile",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:    _textSub,
                  fontSize: 13,
                  height:   1.6,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 32),

              // Gold divider
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
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return widget.loading ? _buildLoading() : _buildEmpty();

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
  const _Particle({
    required this.dx,
    required this.dy,
    required this.size,
  });
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

    canvas.drawArc(
      rect, 0, math.pi * 1.4, false,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap   = StrokeCap.round
        ..shader      = SweepGradient(
          colors: [colorA, colorA.withOpacity(0.0)],
          stops:  const [0.0, 0.7],
        ).createShader(rect),
    );

    canvas.drawArc(
      rect, math.pi, math.pi * 0.8, false,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap   = StrokeCap.round
        ..shader      = SweepGradient(
          colors:     [colorB, colorB.withOpacity(0.0)],
          stops:      const [0.0, 0.5],
          startAngle: math.pi,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────
//  Dashed Circle Painter
// ─────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int   dashCount;
  const _DashedCirclePainter({required this.color, required this.dashCount});

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
        1.4, paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────
//  Sliding Gradient — shimmer
// ─────────────────────────────────────────────

class _SlidingGradient extends GradientTransform {
  final double slideX;
  const _SlidingGradient(this.slideX);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slideX, 0, 0);
  }
}
