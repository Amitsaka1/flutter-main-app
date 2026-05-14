import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  DASHBOARD SEARCH BAR  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class DashboardSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const DashboardSearchBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  State<DashboardSearchBar> createState() => _DashboardSearchBarState();
}

class _DashboardSearchBarState extends State<DashboardSearchBar>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg         = Color(0xFF0E0E18);
  static const _surface    = Color(0xFF13131F);
  static const _borderIdle = Color(0xFF2A2A3A);
  static const _goldA      = Color(0xFFD4A843);
  static const _goldB      = Color(0xFFB8892E);
  static const _textPrime  = Color(0xFFF0EDE8);
  static const _textMuted  = Color(0xFF55556A);
  static const _accentGlow = Color(0xFF6C63FF);

  final FocusNode _focus = FocusNode();
  late AnimationController _ctrl;
  late Animation<double> _borderAnim;
  late Animation<double> _glowAnim;
  bool _isFocused = false;
  bool _hasText   = false;
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _borderAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _glowAnim   = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
      if (_focus.hasFocus) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });

    _textCtrl.addListener(() {
      setState(() => _hasText = _textCtrl.text.isNotEmpty);
      widget.onChanged?.call(_textCtrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _clearText() {
    _textCtrl.clear();
    setState(() => _hasText = false);
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final borderColor = Color.lerp(
          _borderIdle,
          _goldA,
          _borderAnim.value,
        )!;

        final glowOpacity = _glowAnim.value * 0.18;

        return Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Outer glow when focused
            boxShadow: [
              BoxShadow(
                color: _goldA.withOpacity(glowOpacity),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: _accentGlow.withOpacity(glowOpacity * 0.5),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _GradientBorderBox(
            borderColor: borderColor,
            borderRadius: 16,
            borderWidth: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [

                  // ── Search Icon ──────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isFocused
                        ? ShaderMask(
                            key: const ValueKey('focused'),
                            shaderCallback: (b) =>
                                const LinearGradient(
                                  colors: [_goldA, _goldB],
                                ).createShader(b),
                            child: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            key: ValueKey('idle'),
                            Icons.search_rounded,
                            size: 20,
                            color: _textMuted,
                          ),
                  ),

                  const SizedBox(width: 12),

                  // ── Text Field ───────────────────────
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focus,
                      style: const TextStyle(
                        color: _textPrime,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      cursorColor: _goldA,
                      cursorWidth: 1.5,
                      decoration: const InputDecoration(
                        hintText: "Search people, places...",
                        hintStyle: TextStyle(
                          color: _textMuted,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // ── Clear Button ─────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _hasText
                        ? GestureDetector(
                            key: const ValueKey('clear'),
                            onTap: _clearText,
                            child: Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _textMuted.withOpacity(0.25),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: _textMuted,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),

                  // ── Divider ──────────────────────────
                  if (widget.onFilterTap != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _borderIdle,
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ── Filter Button ────────────────
                    GestureDetector(
                      onTap: widget.onFilterTap,
                      child: _FilterIcon(),
                    ),
                  ],

                ],
              ),
            ),
          ),
        );
      },
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Gradient Border Wrapper
// ─────────────────────────────────────────────

class _GradientBorderBox extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;

  const _GradientBorderBox({
    required this.child,
    required this.borderColor,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            borderColor.withOpacity(0.9),
            borderColor.withOpacity(0.3),
            borderColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  Filter Icon — gold gradient
// ─────────────────────────────────────────────

class _FilterIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFD4A843), Color(0xFFE8C86A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: const Icon(
        Icons.tune_rounded,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}
