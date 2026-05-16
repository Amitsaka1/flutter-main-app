import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE FORM SWITCH  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileFormSwitch extends StatefulWidget {
  final String           title;
  final bool             value;
  final ValueChanged<bool> onChanged;

  const ProfileFormSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ProfileFormSwitch> createState() => _ProfileFormSwitchState();
}

class _ProfileFormSwitchState extends State<ProfileFormSwitch>
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
  late Animation<double>   _glowAnim;
  late Animation<double>   _thumbSlide;
  late Animation<double>   _trackColor;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.value ? 1.0 : 0.0,
    );

    _glowAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _thumbSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _trackColor = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(ProfileFormSwitch old) {
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

  // ── Sub label by title ────────────────────────
  String _subLabel() {
    final t = widget.title.toLowerCase();
    if (t.contains("place")) return "I have a private place to meet";
    if (t.contains("notif")) return "Receive push notifications";
    if (t.contains("online")) return "Show my online status";
    return "Toggle this option";
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),

      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {

          final borderColor = Color.lerp(
            _border,
            _goldA.withOpacity(0.55),
            _glowAnim.value,
          )!;

          final trackBg = Color.lerp(
            const Color(0xFF16161F),
            _goldA.withOpacity(0.25),
            _trackColor.value,
          )!;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical:   14,
            ),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),

              // ── Border animated ──────────────────
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),

              // ── Glow on active ───────────────────
              boxShadow: [
                BoxShadow(
                  color: _goldA.withOpacity(_glowAnim.value * 0.10),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),

            child: Row(
              children: [

                // ── Icon ──────────────────────────────
                Container(
                  width:  36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF13131F),
                    border: Border.all(
                      color: widget.value
                          ? _goldA.withOpacity(0.4)
                          : _border,
                      width: 1,
                    ),
                    boxShadow: widget.value
                        ? [
                            BoxShadow(
                              color: _goldA.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size:  17,
                    color: widget.value
                        ? _goldA
                        : _textMuted.withOpacity(0.5),
                  ),
                ),

                const SizedBox(width: 14),

                // ── Text ──────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Text(
                        widget.title,
                        style: TextStyle(
                          color: Color.lerp(
                            _textMuted,
                            _textPrime,
                            _glowAnim.value,
                          ),
                          fontSize:      14,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        _subLabel(),
                        style: TextStyle(
                          color:    _textMuted.withOpacity(0.65),
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── Custom switch track ───────────────
                GestureDetector(
                  onTap: () => widget.onChanged(!widget.value),
                  child: Container(
                    width:  52,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: trackBg,
                      border: Border.all(
                        color: widget.value
                            ? _goldA.withOpacity(0.5)
                            : _border,
                        width: 1,
                      ),
                      boxShadow: widget.value
                          ? [
                              BoxShadow(
                                color: _goldA.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: AnimatedAlign(
                        alignment: widget.value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,

                        // ── Thumb ──────────────────────
                        child: Container(
                          width:  20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: widget.value
                                ? const LinearGradient(
                                    colors: [_goldC, _goldA, _goldB],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: widget.value
                                ? null
                                : const Color(0xFF2A2A3A),
                            boxShadow: widget.value
                                ? [
                                    BoxShadow(
                                      color: _goldA.withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                          ),

                          // Specular on thumb
                          child: widget.value
                              ? Align(
                                  alignment: const Alignment(-0.3, -0.3),
                                  child: Container(
                                    width:  5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.55),
                                    ),
                                  ),
                                )
                              : null,
                        ),
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
