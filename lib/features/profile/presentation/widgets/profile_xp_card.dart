import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE XP CARD  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileXpCard extends StatefulWidget {
  final int    level;
  final int    xp;
  final double progress;

  const ProfileXpCard({
    super.key,
    required this.level,
    required this.xp,
    required this.progress,
  });

  @override
  State<ProfileXpCard> createState() => _ProfileXpCardState();
}

class _ProfileXpCardState extends State<ProfileXpCard>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _accent    = Color(0xFF6C63FF);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  late AnimationController _ctrl;
  late Animation<double>   _entrScale;
  late Animation<double>   _progressAnim;
  late Animation<double>   _glowPulse;
  late Animation<double>   _shimmer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    // Entrance scale
    _entrScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Progress bar fill
    _progressAnim = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Glow breathe — second half repeating feel
    _glowPulse = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Shimmer
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didUpdateWidget(ProfileXpCard old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress || old.level != widget.level) {
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

  // ── Level color tier ──────────────────────────
  List<Color> _levelColors() {
    final lv = widget.level;
    if (lv >= 50) return [_goldC, _goldA, _goldB];
    if (lv >= 30) return [const Color(0xFF4A42CC), _accent, const Color(0xFF8B84FF)];
    if (lv >= 15) return [const Color(0xFF27AE60), const Color(0xFF2ECC71), const Color(0xFF58D68D)];
    return [const Color(0xFF2E86C1), const Color(0xFF5DADE2), const Color(0xFF85C1E9)];
  }

  // ── XP to next level ─────────────────────────
  int get _xpToNext => 100 - (widget.xp % 100);

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    final colors = _levelColors();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {

        return Transform.scale(
          scale: _entrScale.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              // ── Gradient border shell ──────────
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2C2C42),
                  Color(0xFF181824),
                  Color(0xFF2C2C42),
                ],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),

              // ── Glow ──────────────────────────
              boxShadow: [
                BoxShadow(
                  color: _goldA.withOpacity(_glowPulse.value * 0.12),
                  blurRadius:   24,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.2),

            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:        _surfaceHi,
                borderRadius: BorderRadius.circular(19),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Top row — level + xp to next ──
                  Row(
                    children: [

                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical:    6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: colors,
                            begin:  Alignment.topLeft,
                            end:    Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:       colors[1].withOpacity(0.4),
                              blurRadius:  12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size:  13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Level ${widget.level}",
                              style: const TextStyle(
                                color:         Colors.white,
                                fontSize:      12,
                                fontWeight:    FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // XP to next
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical:    5,
                        ),
                        decoration: BoxDecoration(
                          color:        _surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size:  11,
                              color: _goldA.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$_xpToNext XP to next",
                              style: TextStyle(
                                color:         _textMuted,
                                fontSize:      10.5,
                                fontWeight:    FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Progress bar ──────────────────
                  Stack(
                    children: [

                      // Track
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _surface,
                          border: Border.all(
                            color: _border,
                            width: 1,
                          ),
                        ),
                      ),

                      // Fill
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: FractionallySizedBox(
                          widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                          child: Stack(
                            children: [

                              // Gradient fill
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    colors: colors,
                                    begin:  Alignment.centerLeft,
                                    end:    Alignment.centerRight,
                                  ),
                                ),
                              ),

                              // Shimmer on fill
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: Offset(
                                    MediaQuery.of(context).size.width *
                                        _shimmer.value * 0.2,
                                    0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.25),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),

                      // Glow tip dot
                      if (_progressAnim.value > 0.02)
                        Positioned(
                          left: (_progressAnim.value.clamp(0.0, 1.0)) *
                              (MediaQuery.of(context).size.width - 88) - 5,
                          top: -1,
                          child: Container(
                            width:  12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors[1],
                              boxShadow: [
                                BoxShadow(
                                  color:       colors[1].withOpacity(0.8),
                                  blurRadius:  8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Bottom row — xp + percent ─────
                  Row(
                    children: [

                      // XP amount
                      ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: colors,
                        ).createShader(b),
                        child: Text(
                          "${widget.xp} XP",
                          style: const TextStyle(
                            color:         Colors.white,
                            fontSize:      13,
                            fontWeight:    FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Percentage
                      Text(
                        "${(_progressAnim.value * 100).toInt()}%",
                        style: TextStyle(
                          color:         _textMuted,
                          fontSize:      12,
                          fontWeight:    FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),

                    ],
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );

    // ================= UI END =================
  }
}
