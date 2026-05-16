import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CREATE PROFILE CHECKBOX  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class CreateProfileCheckbox extends StatefulWidget {
  final bool              value;
  final ValueChanged<bool?> onChanged;

  const CreateProfileCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CreateProfileCheckbox> createState() => _CreateProfileCheckboxState();
}

class _CreateProfileCheckboxState extends State<CreateProfileCheckbox>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _online    = Color(0xFF39E27A);

  late AnimationController _ctrl;
  late Animation<double>   _checkScale;
  late Animation<double>   _glowAnim;
  late Animation<double>   _rowScale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _rowScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    if (widget.value) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(CreateProfileCheckbox old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
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
      onTap: () => widget.onChanged(!widget.value),

      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),

              // ── Border — idle grey → gold on check ──
              border: Border.all(
                color: Color.lerp(
                  _border,
                  _goldA.withOpacity(0.6),
                  _glowAnim.value,
                )!,
                width: 1.0,
              ),

              // ── Glow on checked ──────────────────
              boxShadow: [
                BoxShadow(
                  color: _goldA.withOpacity(_glowAnim.value * 0.12),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),

            child: Row(
              children: [

                // ── Custom checkbox ───────────────────
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: widget.value
                        ? const LinearGradient(
                            colors: [_goldC, _goldA, _goldB],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: widget.value ? null : const Color(0xFF16161F),
                    border: Border.all(
                      color: widget.value
                          ? Colors.transparent
                          : _border,
                      width: 1.5,
                    ),
                    boxShadow: widget.value
                        ? [
                            BoxShadow(
                              color: _goldA.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),

                  child: widget.value
                      ? Transform.scale(
                          scale: _checkScale.value,
                          child: const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Color(0xFF0A0A0F),
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 14),

                // ── Text + sub label ─────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Have Place",
                        style: TextStyle(
                          color: Color.lerp(
                            _textMuted,
                            _textPrime,
                            _glowAnim.value,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "I have a private place to meet",
                        style: TextStyle(
                          color: _textMuted.withOpacity(0.7),
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Status pill ───────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: widget.value
                      ? Container(
                          key: const ValueKey('yes'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _online.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _online.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _online,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _online.withOpacity(0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "Yes",
                                style: TextStyle(
                                  color: _online,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: const ValueKey('no'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _border.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _border,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            "No",
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                ),

              ],
            ),
          );
        },
      ),
    );

    // ================= UI END =================
  }
}
