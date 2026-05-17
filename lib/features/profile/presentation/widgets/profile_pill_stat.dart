import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE PILL STAT  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfilePillStat extends StatefulWidget {
  final String title;
  final String value;

  const ProfilePillStat({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  State<ProfilePillStat> createState() => _ProfilePillStatState();
}

class _ProfilePillStatState extends State<ProfilePillStat>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  late AnimationController _ctrl;
  late Animation<double>   _glowPulse;
  late Animation<double>   _countAnim;
  late Animation<double>   _entrScale;

  bool _isPressed = false;

  // Parse numeric value for count animation
  int get _numValue => int.tryParse(widget.value) ?? 0;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Entrance scale
    _entrScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Count up animation
    _countAnim = Tween<double>(begin: 0, end: _numValue.toDouble()).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );

    // Glow pulse — repeating
    _glowPulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didUpdateWidget(ProfilePillStat old) {
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
  String _formatValue(String raw) {
    final n = int.tryParse(raw);
    if (n == null) return raw;
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000)    return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  // ── Icon by title ─────────────────────────────
  IconData _icon() {
    final t = widget.title.toLowerCase();
    if (t.contains("follow") && t.contains("ing") && !t.contains("er")) {
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
                      color: _goldA.withOpacity(_glowPulse.value * 0.10),
                      blurRadius:   16,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(1.2),

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical:   16,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceHi,
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
                          // Animate count if numeric
                          int.tryParse(widget.value) != null
                              ? _formatValue(
                                  _countAnim.value.toInt().toString(),
                                )
                              : widget.value,
                          style: const TextStyle(
                            color:         Colors.white,
                            fontSize:      20,
                            fontWeight:    FontWeight.w800,
                            letterSpacing: 0.3,
                            height:        1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

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
