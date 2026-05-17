import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  NAV ITEM  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class NavItem extends StatefulWidget {
  final String     label;
  final IconData   icon;
  final bool       active;
  final VoidCallback onTap;
  final Color?     highlightColor;

  const NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.highlightColor,
  });

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _goldA = Color(0xFFD4A843);
  static const _goldB = Color(0xFFE8C86A);
  static const _muted = Color(0xFF55556A);

  // ── Active glow animation ────────────────────
  late AnimationController _glowCtrl;
  late Animation<double>   _activeGlow;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _activeGlow = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    if (widget.active) _glowCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(NavItem old) {
    super.didUpdateWidget(old);

    if (widget.active && !old.active) {
      _glowCtrl.repeat(reverse: true);
    } else if (!widget.active && old.active) {
      _glowCtrl
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final Color accentA = widget.highlightColor ?? _goldA;
    final Color accentB = widget.highlightColor ?? _goldB;

    // ================= UI START =================

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,

      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) {

          return SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Icon + glow ─────────────────────
                SizedBox(
                  width:  36,
                  height: 36,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [

                      // Active glow ring
                      if (widget.active)
                        Container(
                          width:  36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentA.withOpacity(
                                  _activeGlow.value * 0.25,
                                ),
                                blurRadius:   16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),

                      // Icon container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width:  36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.active
                              ? accentA.withOpacity(0.12)
                              : Colors.transparent,
                          border: widget.active
                              ? Border.all(
                                  color: accentA.withOpacity(0.25),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: widget.active
                            ? ShaderMask(
                                shaderCallback: (b) => LinearGradient(
                                  colors: [accentA, accentB],
                                  begin:  Alignment.topLeft,
                                  end:    Alignment.bottomRight,
                                ).createShader(b),
                                child: Icon(
                                  widget.icon,
                                  size:  22,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                widget.icon,
                                size:  22,
                                color: _muted,
                              ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── Label ──────────────────────────
                widget.active
                    ? ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: [accentA, accentB],
                        ).createShader(b),
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            color:         Colors.white,
                            fontSize:      11,
                            fontWeight:    FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          color:         _muted,
                          fontSize:      11,
                          fontWeight:    FontWeight.w400,
                          letterSpacing: 0.3,
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
