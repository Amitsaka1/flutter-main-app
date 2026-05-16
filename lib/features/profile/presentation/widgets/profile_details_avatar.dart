import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE DETAILS AVATAR  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileDetailsAvatar extends StatefulWidget {
  final String? avatar;
  final bool    isOnline;

  const ProfileDetailsAvatar({
    super.key,
    required this.avatar,
    required this.isOnline,
  });

  @override
  State<ProfileDetailsAvatar> createState() => _ProfileDetailsAvatarState();
}

class _ProfileDetailsAvatarState extends State<ProfileDetailsAvatar>
    with TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg      = Color(0xFF0A0A0F);
  static const _goldA   = Color(0xFFD4A843);
  static const _goldB   = Color(0xFFE8C86A);
  static const _goldC   = Color(0xFFB8892E);
  static const _accent  = Color(0xFF6C63FF);
  static const _online  = Color(0xFF39E27A);

  // ── Controllers ──────────────────────────────
  late AnimationController _ringCtrl;   // rotating arc
  late AnimationController _pulseCtrl;  // glow breathe
  late AnimationController _dotCtrl;    // online dot pulse
  late AnimationController _entrCtrl;   // entrance scale

  late Animation<double> _ringRotate;
  late Animation<double> _glowPulse;
  late Animation<double> _dotPulse;
  late Animation<double> _dotOpacity;
  late Animation<double> _entrScale;

  @override
  void initState() {
    super.initState();

    // Rotating arc ring — slow elegant
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();

    _ringRotate = Tween<double>(begin: 0, end: 6.2832).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.linear),
    );

    // Glow breathe
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Online dot ripple
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _dotPulse = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _dotCtrl, curve: Curves.easeOut),
    );

    _dotOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _dotCtrl, curve: Curves.easeOut),
    );

    if (widget.isOnline) _dotCtrl.repeat();

    // Entrance scale
    _entrCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _entrScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrCtrl,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void didUpdateWidget(ProfileDetailsAvatar old) {
    super.didUpdateWidget(old);
    if (old.isOnline != widget.isOnline) {
      widget.isOnline ? _dotCtrl.repeat() : _dotCtrl.stop();
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _dotCtrl.dispose();
    _entrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    final bool hasAvatar = widget.avatar != null &&
        widget.avatar!.isNotEmpty;

    return AnimatedBuilder(
      animation: _entrScale,
      builder: (_, child) => Transform.scale(
        scale: _entrScale.value,
        child: child,
      ),
      child: SizedBox(
        width:  170,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [

            // ── Ambient glow ─────────────────────
            AnimatedBuilder(
              animation: _glowPulse,
              builder: (_, __) => Container(
                width:  160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _goldA.withOpacity(
                        _glowPulse.value * 0.15,
                      ),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: _accent.withOpacity(
                        _glowPulse.value * 0.07,
                      ),
                      blurRadius: 60,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
            ),

            // ── Rotating arc ring ─────────────────
            AnimatedBuilder(
              animation: _ringRotate,
              builder: (_, __) => Transform.rotate(
                angle: _ringRotate.value,
                child: CustomPaint(
                  size: const Size(158, 158),
                  painter: _ArcRingPainter(
                    colorA: _goldA,
                    colorB: _accent,
                  ),
                ),
              ),
            ),

            // ── Gold border ring ──────────────────
            Container(
              width:  148,
              height: 148,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_goldA, _goldB, _goldC, _goldA],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(3),

              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bg,
                ),
                padding: const EdgeInsets.all(3),

                // ── Avatar ──────────────────────────
                child: CircleAvatar(
                  radius: 66,
                  backgroundColor: const Color(0xFF1C1C2A),
                  backgroundImage: hasAvatar
                      ? NetworkImage(widget.avatar!)
                      : const AssetImage(
                              "assets/profile_placeholder.png")
                          as ImageProvider,
                ),
              ),
            ),

            // ── Online dot + ripple ───────────────
            Positioned(
              bottom: 12,
              right:  12,
              child: SizedBox(
                width:  28,
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // Ripple ring
                    if (widget.isOnline)
                      AnimatedBuilder(
                        animation: _dotCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _dotPulse.value,
                          child: Opacity(
                            opacity: _dotOpacity.value,
                            child: Container(
                              width:  14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _online.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Dark bg disc
                    Container(
                      width:  18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _bg,
                      ),
                    ),

                    // Core dot
                    Container(
                      width:  12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isOnline
                            ? _online
                            : const Color(0xFF3A3A55),
                        boxShadow: widget.isOnline
                            ? [
                                BoxShadow(
                                  color: _online.withOpacity(0.7),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                    ),

                    // Specular
                    if (widget.isOnline)
                      Positioned(
                        top:  7,
                        left: 8,
                        child: Container(
                          width:  3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );

    // ================= UI END =================
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
    final radius = size.width / 2 - 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Gold arc
    final paintGold = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors: [colorA, colorA.withOpacity(0.0)],
        stops:  const [0.0, 0.65],
      ).createShader(rect);

    canvas.drawArc(rect, 0, 4.0, false, paintGold);

    // Accent arc
    final paintAccent = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors:     [colorB, colorB.withOpacity(0.0)],
        stops:      const [0.0, 0.45],
        startAngle: 3.14,
      ).createShader(rect);

    canvas.drawArc(rect, 3.14, 2.4, false, paintAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
