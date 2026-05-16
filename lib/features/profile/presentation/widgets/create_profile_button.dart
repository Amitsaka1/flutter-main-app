import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CREATE PROFILE BUTTON  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class CreateProfileButton extends StatefulWidget {
  final bool          loading;
  final VoidCallback  onPressed;

  const CreateProfileButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<CreateProfileButton> createState() => _CreateProfileButtonState();
}

class _CreateProfileButtonState extends State<CreateProfileButton>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _goldA  = Color(0xFFD4A843);
  static const _goldB  = Color(0xFFE8C86A);
  static const _goldC  = Color(0xFFB8892E);
  static const _bg     = Color(0xFF0A0A0F);

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

    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
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
      onTapUp:     (_) => setState(() => _isPressed = false),
      onTapCancel: ()  => setState(() => _isPressed = false),
      onTap: widget.loading ? null : widget.onPressed,

      child: AnimatedScale(
        scale:    _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,

        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),

                // ── Gold gradient fill ───────────
                gradient: widget.loading
                    ? LinearGradient(
                        colors: [
                          _goldC.withOpacity(0.5),
                          _goldA.withOpacity(0.4),
                        ],
                      )
                    : const LinearGradient(
                        colors: [_goldC, _goldA, _goldB, _goldA],
                        stops: [0.0, 0.35, 0.65, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),

                // ── Glow shadow ──────────────────
                boxShadow: widget.loading
                    ? []
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
                            _glowPulse.value * 0.2,
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

                    // ── Shimmer sweep ──────────────
                    if (!widget.loading)
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(
                            MediaQuery.of(context).size.width *
                                _shimmer.value *
                                0.4,
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
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    _bg.withOpacity(0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Creating...",
                                style: TextStyle(
                                  color: _bg.withOpacity(0.6),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_add_rounded,
                                size: 18,
                                color: Color(0xFF0A0A0F),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Create Profile",
                                style: TextStyle(
                                  color: Color(0xFF0A0A0F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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
