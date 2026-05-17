import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE STAT BOX  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileStatBox extends StatefulWidget {
  final String title;
  final int    value;

  const ProfileStatBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  State<ProfileStatBox> createState() => _ProfileStatBoxState();
}

class _ProfileStatBoxState extends State<ProfileStatBox>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF2A2A3A);
  static const _textMuted = Color(0xFF55556A);

  late AnimationController _ctrl;
  late Animation<double>   _entrScale;
  late Animation<double>   _countAnim;
  late Animation<double>   _glowPulse;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Entrance scale
    _entrScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Count-up
    _countAnim = Tween<double>(
      begin: 0,
      end:   widget.value.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );

    // Glow
    _glowPulse = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didUpdateWidget(ProfileStatBox old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Format large numbers ──────────────────────
  String _format(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000)    return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  // ── Icon by title ─────────────────────────────
  IconData _icon() {
    final t = widget.title.toLowerCase();
    if (t.contains("follow") && !t.contains("er")) {
      return Icons.person_add_outlined;
    }
    if (t.contains("follower")) return Icons.people_outline_rounded;
    if (t.contains("post"))     return Icons.grid_view_rounded;
    if (t.contains("like"))     return Icons.favorite_border_rounded;
    return Icons.bar_chart_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return GestureDetector(
      onTapDown:   (_) => setState(() => _isPressed = true),
      onTapUp:     (_) => setState(() => _isPressed = false),
      onTapCancel: ()  => setState(() => _isPressed = false),

      child: AnimatedScale(
        scale:    _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,

        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {

            return Transform.scale(
              scale: _entrScale.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),

                  // ── Gradient border shell ────────
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2C2C42),
                      Color(0xFF181824),
                      Color(0xFF2C2C42),
                    ],
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                  ),

                  // ── Glow ────────────────────────
                  boxShadow: [
                    BoxShadow(
                      color: _goldA.withOpacity(
                        _glowPulse.value * 0.10,
                      ),
                      blurRadius:   18,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(1.2),

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical:   18,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color:        _surfaceHi,
                    borderRadius: BorderRadius.circular(17),
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ── Icon ──────────────────────
                      Container(
                        width:  32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _surface,
                          border: Border.all(
                            color: _border,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _icon(),
                          size:  15,
                          color: _goldA.withOpacity(0.75),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Animated count ────────────
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_goldA, _goldB],
                          begin:  Alignment.topLeft,
                          end:    Alignment.bottomRight,
                        ).createShader(b),
                        child: Text(
                          _format(_countAnim.value.toInt()),
                          style: const TextStyle(
                            color:         Colors.white,
                            fontSize:      22,
                            fontWeight:    FontWeight.w800,
                            letterSpacing: 0.3,
                            height:        1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── Title ─────────────────────
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color:         _textMuted,
                          fontSize:      11.5,
                          fontWeight:    FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // ================= UI END =================
  }
}
