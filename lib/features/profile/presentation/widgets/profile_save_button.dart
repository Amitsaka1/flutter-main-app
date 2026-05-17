import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE SAVE BUTTON  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileSaveButton extends StatefulWidget {
  final bool         loading;
  final VoidCallback onPressed;

  const ProfileSaveButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<ProfileSaveButton> createState() => _ProfileSaveButtonState();
}

class _ProfileSaveButtonState extends State<ProfileSaveButton>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg     = Color(0xFF0A0A0F);
  static const _goldA  = Color(0xFFD4A843);
  static const _goldB  = Color(0xFFE8C86A);
  static const _goldC  = Color(0xFFB8892E);

  late AnimationController _ctrl;
  late Animation<double>   _glowPulse;
  late Animation<double>   _shimmer;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.45, end: 1.0).animate(
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
        if (!widget.loading) widget.onPressed();
      },
      onTapCancel: ()  => setState(() => _isPressed = false),

      child: AnimatedScale(
        scale:    _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,

        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {

            return Container(
              height: 54,
              width:  double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),

                // ── Gold gradient fill ─────────────
                gradient: widget.loading
                    ? LinearGradient(
                        colors: [
                          _goldC.withOpacity(0.45),
                          _goldA.withOpacity(0.35),
                        ],
                      )
                    : const LinearGradient(
                        colors: [_goldC, _goldA, _goldB, _goldA],
                        stops:  [0.0, 0.35, 0.65, 1.0],
                        begin:  Alignment.centerLeft,
                        end:    Alignment.centerRight,
                      ),

                // ── Glow shadow ───────────────────
                boxShadow: widget.loading
                    ? []
                    : [
                        BoxShadow(
                          color: _goldA.withOpacity(
                            _glowPulse.value * 0.45,
                          ),
                          blurRadius:   22,
                          spreadRadius: -2,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: _goldA.withOpacity(
                            _glowPulse.value * 0.18,
                          ),
                          blurRadius:   40,
                          spreadRadius: -4,
                          offset: const Offset(0, 12),
                        ),
                      ],
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // ── Shimmer sweep ──────────────
                    if (!widget.loading)
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
                    widget.loading

                        // Loading state
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width:  18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    _bg.withOpacity(0.55),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Saving...",
                                style: TextStyle(
                                  color:         _bg.withOpacity(0.55),
                                  fontSize:      15,
                                  fontWeight:    FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          )

                        // Idle state
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_rounded,
                                size:  18,
                                color: Color(0xFF0A0A0F),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Save Changes",
                                style: TextStyle(
                                  color:         Color(0xFF0A0A0F),
                                  fontSize:      15,
                                  fontWeight:    FontWeight.w700,
                                  letterSpacing: 0.5,
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
