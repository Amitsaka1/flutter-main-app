import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE EDIT BUTTON  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileEditButton extends StatefulWidget {
  final VoidCallback onTap;

  const ProfileEditButton({
    super.key,
    required this.onTap,
  });

  @override
  State<ProfileEditButton> createState() => _ProfileEditButtonState();
}

class _ProfileEditButtonState extends State<ProfileEditButton>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF14141F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
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

    _glowPulse = Tween<double>(begin: 0.3, end: 0.7).animate(
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
                    Color(0xFF2C2C42),
                    Color(0xFF1A1A28),
                    Color(0xFF2C2C42),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                // ── Subtle glow ───────────────────
                boxShadow: [
                  BoxShadow(
                    color: _goldA.withOpacity(_glowPulse.value * 0.12),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
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
                      decoration: const BoxDecoration(
                        color: _surfaceHi,
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
                                Colors.white.withOpacity(0.04),
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

                        // Icon in gold pill
                        Container(
                          width:  28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_goldC, _goldA],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _goldA.withOpacity(0.35),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: Color(0xFF0A0A0F),
                          ),
                        ),

                        const SizedBox(width: 10),

                        const Text(
                          "Edit Profile",
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
