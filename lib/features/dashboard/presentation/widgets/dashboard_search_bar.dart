import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  DASHBOARD SEARCH BAR  —  Premium Dark VIP Edition
//  (Performance Optimized — UI Unchanged)
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

class _DashboardSearchBarState extends State<DashboardSearchBar> {

  // ── Palette (static const) ───────────────────
  static const _surface    = Color(0xFF13131F);
  static const _borderIdle = Color(0xFF2A2A3A);
  static const _borderFocus= Color(0xFFD4A843);
  static const _goldA      = Color(0xFFD4A843);
  static const _textPrime  = Color(0xFFF0EDE8);
  static const _textMuted  = Color(0xFF55556A);

  final FocusNode           _focus   = FocusNode();
  final TextEditingController _textCtrl = TextEditingController();

  bool _isFocused = false;
  bool _hasText   = false;

  @override
  void initState() {
    super.initState();

    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
    });

    _textCtrl.addListener(() {
      final has = _textCtrl.text.isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
      widget.onChanged?.call(_textCtrl.text);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _clearText() {
    _textCtrl.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    // ⚡ AnimationController hataya — border color
    // directly setState se switch hota hai, same visual
    final borderColor = _isFocused ? _borderFocus : _borderIdle;
    final iconColor   = _isFocused ? _goldA : _textMuted;

    return Container(
      height: 52,
      // ── Outer glow — sirf focused pe ──────────
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: _goldA.withOpacity(0.15),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),

      // ── Gradient border shell ─────────────────
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.all(1.0),

        // ── Inner surface ─────────────────────────
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [

              // ── Search icon ───────────────────────
              Icon(
                Icons.search_rounded,
                size: 20,
                color: iconColor,
              ),

              const SizedBox(width: 12),

              // ── Text field ────────────────────────
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

              // ── Clear button ──────────────────────
              if (_hasText)
                GestureDetector(
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
                ),

              // ── Divider + Filter ──────────────────
              if (widget.onFilterTap != null) ...[
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 20,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFF2A2A3A),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: widget.onFilterTap,
                  child: ShaderMask(
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
                  ),
                ),
              ],

            ],
          ),
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
