import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─────────────────────────────────────────────
//  PROFILE AVATAR SECTION  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileAvatarSection extends StatefulWidget {
  final String?   avatar;
  final int       level;
  final VoidCallback onPickImage;

  const ProfileAvatarSection({
    super.key,
    required this.avatar,
    required this.level,
    required this.onPickImage,
  });

  @override
  State<ProfileAvatarSection> createState() => _ProfileAvatarSectionState();
}

class _ProfileAvatarSectionState extends State<ProfileAvatarSection>
    with TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg      = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF0E0E18);
  static const _goldA   = Color(0xFFD4A843);
  static const _goldB   = Color(0xFFE8C86A);
  static const _goldC   = Color(0xFFB8892E);
  static const _accent  = Color(0xFF6C63FF);
  static const _border  = Color(0xFF2A2A3A);

  // ── Controllers ──────────────────────────────
  late AnimationController _ringCtrl;    // rotating gold ring
  late AnimationController _pulseCtrl;   // avatar glow breathe
  late AnimationController _camCtrl;     // camera button bounce
  late AnimationController _levelCtrl;   // level badge entrance

  late Animation<double> _ringRotate;
  late Animation<double> _glowPulse;
  late Animation<double> _camScale;
  late Animation<double> _levelScale;

  bool _camPressed = false;

  @override
  void initState() {
    super.initState();

    // Rotating outer ring
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _ringRotate = Tween<double>(begin: 0, end: 6.2832).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.linear),
    );

    // Glow breathe
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Camera button
    _camCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _camScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _camCtrl, curve: Curves.easeOut),
    );

    // Level badge entrance
    _levelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _levelScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _camCtrl.dispose();
    _levelCtrl.dispose();
    super.dispose();
  }

  // ── Level color tier ──────────────────────────
  List<Color> _levelGradient() {
    final lv = widget.level;
    if (lv >= 50) return [const Color(0xFFE8C86A), const Color(0xFFD4A843)]; // gold
    if (lv >= 30) return [const Color(0xFF9B59B6), const Color(0xFF6C63FF)]; // purple
    if (lv >= 15) return [const Color(0xFF2ECC71), const Color(0xFF27AE60)]; // green
    return [const Color(0xFF5DADE2), const Color(0xFF2E86C1)];               // blue
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    final bool hasAvatar = widget.avatar != null &&
        widget.avatar!.isNotEmpty;

    final levelColors = _levelGradient();

    return SizedBox(
      width:  160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [

          // ── Ambient glow ───────────────────────
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (_, __) => Container(
              width:  148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _goldA.withOpacity(_glowPulse.value * 0.18),
                    blurRadius: 36,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: _accent.withOpacity(_glowPulse.value * 0.08),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          // ── Rotating arc ring ──────────────────
          AnimatedBuilder(
            animation: _ringRotate,
            builder: (_, __) => Transform.rotate(
              angle: _ringRotate.value,
              child: CustomPaint(
                size: const Size(148, 148),
                painter: _ArcRingPainter(
                  colorA: _goldA,
                  colorB: _accent,
                ),
              ),
            ),
          ),

          // ── Gold border ring ───────────────────
          Container(
            width:  136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
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

              // ── Avatar ───────────────────────────
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF1C1C2A),
                backgroundImage: hasAvatar
                    ? CachedNetworkImageProvider(widget.avatar!)
                    : const AssetImage(
                            "assets/profile_placeholder.png")
                        as ImageProvider,
              ),
            ),
          ),

          // ── Camera button ──────────────────────
          Positioned(
            bottom: 6,
            right:  6,
            child: GestureDetector(
              onTapDown: (_) {
                setState(() => _camPressed = true);
                _camCtrl.forward();
              },
              onTapUp: (_) {
                setState(() => _camPressed = false);
                _camCtrl.reverse();
                widget.onPickImage();
              },
              onTapCancel: () {
                setState(() => _camPressed = false);
                _camCtrl.reverse();
              },
              child: AnimatedBuilder(
                animation: _camScale,
                builder: (_, child) => Transform.scale(
                  scale: _camScale.value,
                  child: child,
                ),
                child: Container(
                  width:  38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_goldC, _goldA, _goldB],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: _bg,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _goldA.withOpacity(0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Color(0xFF0A0A0F),
                  ),
                ),
              ),
            ),
          ),

          // ── Level badge ────────────────────────
          Positioned(
            top: -2,
            child: AnimatedBuilder(
              animation: _levelScale,
              builder: (_, child) => Transform.scale(
                scale: _levelScale.value,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical:   5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: levelColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _bg,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: levelColors.first.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 11,
                      color: Color(0xFF0A0A0F),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "LV ${widget.level}",
                      style: const TextStyle(
                        color:       Color(0xFF0A0A0F),
                        fontSize:    11,
                        fontWeight:  FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
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
        stops:  const [0.0, 0.6],
      ).createShader(rect);

    canvas.drawArc(rect, 0, 3.8, false, paintGold);

    // Accent arc
    final paintAccent = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors:     [colorB, colorB.withOpacity(0.0)],
        stops:      const [0.0, 0.4],
        startAngle: 3.14,
      ).createShader(rect);

    canvas.drawArc(rect, 3.14, 2.2, false, paintAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
