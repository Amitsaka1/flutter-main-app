import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  ONLINE INDICATOR  —  Premium Dark VIP Edition
//  (Performance Optimized — UI Unchanged)
// ─────────────────────────────────────────────

class OnlineIndicator extends StatelessWidget {
  final double size;

  const OnlineIndicator({
    super.key,
    this.size = 10.0,
  });

  // ── Palette (static const) ───────────────────
  static const _dot    = Color(0xFF39E27A);
  static const _darkBg = Color(0xFF0E0E18);

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    final double canvasSize = size * 2.8;

    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: Stack(
        alignment: Alignment.center,
        children: [

          // ── Dark bg disc ───────────────────────
          Container(
            width: size + 6,
            height: size + 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _darkBg,
            ),
          ),

          // ── Core dot + glow ────────────────────
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dot,
              boxShadow: [
                // Tight inner glow
                BoxShadow(
                  color: _dot.withOpacity(0.85),
                  blurRadius: size * 0.8,
                  spreadRadius: 0,
                ),
                // Soft outer halo
                BoxShadow(
                  color: _dot.withOpacity(0.30),
                  blurRadius: size * 2.0,
                  spreadRadius: size * 0.1,
                ),
              ],
            ),
          ),

          // ── Specular shine ─────────────────────
          Positioned(
            top:  canvasSize / 2 - size / 2 + 1,
            left: canvasSize / 2 - size / 2 + 1,
            child: Container(
              width:  size * 0.35,
              height: size * 0.35,
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
