import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  BOTTOM CONTROLS  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class BottomControls extends StatefulWidget {
  final VoidCallback onChat;
  final VoidCallback onGift;

  const BottomControls({
    super.key,
    required this.onChat,
    required this.onGift,
  });

  @override
  State<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<BottomControls>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _accent    = Color(0xFF6C63FF);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  // ── Glow pulse ───────────────────────────────
  late AnimationController _glowCtrl;
  late Animation<double>   _glowPulse;

  // Track pressed state per button
  final Map<String, bool> _pressed = {
    'gift':  false,
    'chat':  false,
    'mic':   false,
    'frame': false,
  };

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Control item builder ──────────────────────
  Widget _buildItem({
    required String    key,
    required IconData  icon,
    required String    label,
    required List<Color> colors,
    VoidCallback?      onTap,
    bool               hasGlow = false,
  }) {
    final isPressed = _pressed[key] ?? false;

    return GestureDetector(
      onTapDown: (_) {
        if (onTap != null) setState(() => _pressed[key] = true);
      },
      onTapUp: (_) {
        setState(() => _pressed[key] = false);
        onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed[key] = false),

      child: AnimatedScale(
        scale:    isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,

        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Icon container ───────────────
              AnimatedBuilder(
                animation: _glowPulse,
                builder: (_, __) => Container(
                  width:  46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _surfaceHi,
                    border: Border.all(
                      color: onTap != null
                          ? colors[0].withOpacity(0.35)
                          : _border,
                      width: 1,
                    ),
                    boxShadow: hasGlow && onTap != null
                        ? [
                            BoxShadow(
                              color: colors[0].withOpacity(
                                _glowPulse.value * 0.35,
                              ),
                              blurRadius:   16,
                              spreadRadius: 0,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color:      Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: onTap != null
                          ? colors
                          : [_textMuted, _textMuted],
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ).createShader(b),
                    child: Icon(
                      icon,
                      size:  22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ── Label ────────────────────────
              Text(
                label,
                style: TextStyle(
                  color:      onTap != null ? _textPrime : _textMuted,
                  fontSize:   11,
                  fontWeight: onTap != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        // ── Gradient border shell ──────────────
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C2C42),
            Color(0xFF181824),
            Color(0xFF2C2C42),
          ],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),

        boxShadow: [
          BoxShadow(
            color:       Colors.black.withOpacity(0.5),
            blurRadius:  30,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color:       _goldA.withOpacity(0.05),
            blurRadius:  40,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical:   14,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D1A),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              // ── Gift ─────────────────────────
              _buildItem(
                key:     'gift',
                icon:    Icons.card_giftcard_rounded,
                label:   "Gift",
                colors:  [_goldA, _goldB],
                onTap:   widget.onGift,
                hasGlow: true,
              ),

              // ── Vertical divider ──────────────
              Container(
                width:  1,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _border,
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                  ),
                ),
              ),

              // ── Chat ─────────────────────────
              _buildItem(
                key:     'chat',
                icon:    Icons.chat_bubble_rounded,
                label:   "Chat",
                colors:  [_accent, const Color(0xFF8B84FF)],
                onTap:   widget.onChat,
                hasGlow: true,
              ),

              // ── Vertical divider ──────────────
              Container(
                width:  1,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _border,
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                  ),
                ),
              ),

              // ── Mic ───────────────────────────
              _buildItem(
                key:    'mic',
                icon:   Icons.mic_rounded,
                label:  "Mic",
                colors: [
                  const Color(0xFF39E27A),
                  const Color(0xFF27AE60),
                ],
              ),

              // ── Vertical divider ──────────────
              Container(
                width:  1,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _border,
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                  ),
                ),
              ),

              // ── Frame ─────────────────────────
              _buildItem(
                key:    'frame',
                icon:   Icons.photo_frame_back_rounded,
                label:  "Frame",
                colors: [
                  const Color(0xFF9B59B6),
                  const Color(0xFF6C63FF),
                ],
              ),

            ],
          ),
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
