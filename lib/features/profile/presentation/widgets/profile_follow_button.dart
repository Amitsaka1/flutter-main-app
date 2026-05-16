import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE FOLLOW BUTTON  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileFollowButton extends StatefulWidget {
  final bool         isFollowing;
  final bool         actionLoading;
  final VoidCallback onTap;

  const ProfileFollowButton({
    super.key,
    required this.isFollowing,
    required this.actionLoading,
    required this.onTap,
  });

  @override
  State<ProfileFollowButton> createState() => _ProfileFollowButtonState();
}

class _ProfileFollowButtonState extends State<ProfileFollowButton>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF14141F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  late AnimationController _ctrl;
  late Animation<double>   _glowPulse;
  late Animation<double>   _shimmer;
  late Animation<double>   _stateSwitch;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _stateSwitch = Tween<double>(begin: 0.0, end: 1.0).animate(
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
        if (!widget.actionLoading) widget.onTap();
      },
      onTapCancel: ()  => setState(() => _isPressed = false),

      child: AnimatedScale(
        scale:    _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,

        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {

            // ── Following state → muted dark ──────
            // ── Not following  → gold gradient ────
            final isFollowing = widget.isFollowing;

            return Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),

                // ── Gradient fill ─────────────────
                gradient: isFollowing
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF1A1A28),
                          const Color(0xFF222233),
                        ],
                      )
                    : const LinearGradient(
                        colors: [_goldC, _goldA, _goldB, _goldA],
                        stops:  [0.0, 0.35, 0.65, 1.0],
                        begin:  Alignment.centerLeft,
                        end:    Alignment.centerRight,
                      ),

                // ── Border ────────────────────────
                border: isFollowing
                    ? Border.all(color: _border, width: 1)
                    : null,

                // ── Glow ──────────────────────────
                boxShadow: widget.actionLoading
                    ? []
                    : isFollowing
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: _goldA.withOpacity(
                                _glowPulse.value * 0.45,
                              ),
                              blurRadius: 20,
                              spreadRadius: -2,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: _goldA.withOpacity(
                                _glowPulse.value * 0.18,
                              ),
                              blurRadius: 40,
                              spreadRadius: -4,
                              offset: const Offset(0, 10),
                            ),
                          ],
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // ── Shimmer — only on Follow ───
                    if (!isFollowing && !widget.actionLoading)
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(
                            MediaQuery.of(context).size.width *
                                _shimmer.value * 0.4,
                            0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.12),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Content ────────────────────
                    widget.actionLoading

                        // Loading spinner
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width:  18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    isFollowing
                                        ? _textMuted
                                        : _bg.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isFollowing
                                    ? "Unfollowing..."
                                    : "Following...",
                                style: TextStyle(
                                  color: isFollowing
                                      ? _textMuted
                                      : _bg.withOpacity(0.7),
                                  fontSize:      14,
                                  fontWeight:    FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          )

                        // Follow / Following label
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(
                              scale: anim,
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            ),
                            child: isFollowing

                                // ── Following state ───────
                                ? Row(
                                    key: const ValueKey('following'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        size:  16,
                                        color: _goldA.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Following",
                                        style: TextStyle(
                                          color:         _textPrime.withOpacity(0.7),
                                          fontSize:      14,
                                          fontWeight:    FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  )

                                // ── Follow state ──────────
                                : Row(
                                    key: const ValueKey('follow'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.person_add_rounded,
                                        size:  16,
                                        color: Color(0xFF0A0A0F),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Follow",
                                        style: TextStyle(
                                          color:         Color(0xFF0A0A0F),
                                          fontSize:      14,
                                          fontWeight:    FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
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
