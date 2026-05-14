import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  ONLINE INDICATOR  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class OnlineIndicator extends StatefulWidget {
  /// Dot size (default 10)
  final double size;

  /// Outer ring visible (default true)
  final bool showRing;

  const OnlineIndicator({
    super.key,
    this.size = 10.0,
    this.showRing = true,
  });

  @override
  State<OnlineIndicator> createState() => _OnlineIndicatorState();
}

class _OnlineIndicatorState extends State<OnlineIndicator>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _dotColor   = Color(0xFF39E27A);
  static const _ringColor  = Color(0xFF39E27A);
  static const _darkBg     = Color(0xFF0E0E18);

  late AnimationController _ctrl;
  late Animation<double>   _pulseScale;
  late Animation<double>   _pulseOpacity;
  late Animation<double>   _coreGlow;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Ripple ring expands outward and fades
    _pulseScale = Tween<double>(begin: 1.0, end: 2.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _pulseOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // Core dot subtly breathes
    _coreGlow = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    final double s      = widget.size;
    final double canvasSize = s * 3.2;

    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: Stack(
        alignment: Alignment.center,
        children: [

          // ── Dark bg disc (sits behind everything) ──
          if (widget.showRing)
            Container(
              width: s + 6,
              height: s + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _darkBg,
              ),
            ),

          // ── Expanding ripple ───────────────────────
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: _pulseScale.value,
              child: Opacity(
                opacity: _pulseOpacity.value,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ringColor.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),

          // ── Breathing core dot ─────────────────────
          AnimatedBuilder(
            animation: _coreGlow,
            builder: (_, __) => Transform.scale(
              scale: _coreGlow.value,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _dotColor,
                  boxShadow: [
                    // Tight inner glow
                    BoxShadow(
                      color: _dotColor.withOpacity(0.9),
                      blurRadius: s * 0.6,
                      spreadRadius: 0,
                    ),
                    // Soft wide halo
                    BoxShadow(
                      color: _dotColor.withOpacity(0.3),
                      blurRadius: s * 1.8,
                      spreadRadius: s * 0.2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Specular shine (top-left highlight) ────
          Positioned(
            top: canvasSize / 2 - s / 2 + 1,
            left: canvasSize / 2 - s / 2 + 1,
            child: Container(
              width: s * 0.35,
              height: s * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

        ],
      ),
    );

    // ===================== UI END =======================
  }
}
