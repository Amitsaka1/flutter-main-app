import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE MESSAGE BUTTON  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileMessageButton extends StatefulWidget {
  final VoidCallback onTap;

  const ProfileMessageButton({
    super.key,
    required this.onTap,
  });

  @override
  State<ProfileMessageButton> createState() => _ProfileMessageButtonState();
}

class _ProfileMessageButtonState extends State<ProfileMessageButton>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _accent    = Color(0xFF6C63FF);
  static const _accentLt  = Color(0xFF8B84FF);
  static const _accentDk  = Color(0xFF4A42CC);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  late AnimationController _ctrl;
  late Animation<double>   _glowPulse;
  late Animation<double>   _shimmer;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return GestureDetector(
      onTapDown:   (_) => setState(() => _isPressed = true),
      onTapUp:     (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: ()  => setState(() => _isPressed = false),

      child: AnimatedScale(
        scale:    _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,

        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {

            return Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),

                // ── Gradient border shell ──────────
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3A3560),
                    Color(0xFF1E1B3A),
                    Color(0xFF3A3560),
                  ],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),

                // ── Accent glow ───────────────────
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(
                      _glowPulse.value * 0.35,
                    ),
                    blurRadius:   18,
                    spreadRadius: -2,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: _accent.withOpacity(
                      _glowPulse.value * 0.15,
                    ),
                    blurRadius:   35,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(1.2),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // ── Dark surface ───────────────
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF16152A),
                            Color(0xFF1A1830),
                          ],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // ── Shimmer sweep ──────────────
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(
                          MediaQuery.of(context).size.width *
                              _shimmer.value * 0.3,
                          0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                _accentLt.withOpacity(0.06),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Content ────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // Icon in accent pill
                        Container(
                          width:  28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_accentDk, _accent, _accentLt],
                              begin: Alignment.topLeft,
                              end:   Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:       _accent.withOpacity(0.45),
                                blurRadius:  10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            size:  13,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 10),

                        const Text(
                          "Message",
                          style: TextStyle(
                            color:         _textPrime,
                            fontSize:      14,
                            fontWeight:    FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),

                      ],
                    ),

                  ],
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
