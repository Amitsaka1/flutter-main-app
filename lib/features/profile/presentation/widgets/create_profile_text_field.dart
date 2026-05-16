import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CREATE PROFILE TEXT FIELD  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class CreateProfileTextField extends StatefulWidget {
  final TextEditingController       controller;
  final String                      label;
  final String? Function(String?)?  validator;
  final TextInputType?               keyboardType;

  const CreateProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
  });

  @override
  State<CreateProfileTextField> createState() =>
      _CreateProfileTextFieldState();
}

class _CreateProfileTextFieldState extends State<CreateProfileTextField>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _error     = Color(0xFFE05C5C);

  final FocusNode _focus = FocusNode();

  late AnimationController _ctrl;
  late Animation<double>   _glowAnim;
  late Animation<double>   _borderAnim;

  bool _isFocused  = false;
  bool _hasText    = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _glowAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _borderAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
      _focus.hasFocus ? _ctrl.forward() : _ctrl.reverse();
    });

    widget.controller.addListener(() {
      final has = widget.controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });

    // If pre-filled
    if (widget.controller.text.isNotEmpty) {
      _hasText = true;
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Prefix icon by field type ─────────────────
  IconData _prefixIcon() {
    final label = widget.label.toLowerCase();
    if (label.contains("name"))     return Icons.person_outline_rounded;
    if (label.contains("age"))      return Icons.cake_outlined;
    if (label.contains("username")) return Icons.alternate_email_rounded;
    if (label.contains("email"))    return Icons.mail_outline_rounded;
    return Icons.edit_outlined;
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {

        final borderColor = Color.lerp(
          _border,
          _goldA.withOpacity(0.7),
          _borderAnim.value,
        )!;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),

            // ── Focus glow ──────────────────────
            boxShadow: [
              BoxShadow(
                color: _goldA.withOpacity(_glowAnim.value * 0.14),
                blurRadius: 18,
                spreadRadius: -1,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: TextFormField(
            controller:  widget.controller,
            focusNode:   _focus,
            keyboardType: widget.keyboardType,
            validator:   widget.validator,
            cursorColor: _goldA,
            cursorWidth: 1.5,

            style: const TextStyle(
              color:         _textPrime,
              fontSize:      14.5,
              fontWeight:    FontWeight.w400,
              letterSpacing: 0.3,
            ),

            decoration: InputDecoration(

              // ── Label ───────────────────────────
              labelText: widget.label,
              labelStyle: TextStyle(
                color: _isFocused
                    ? _goldA
                    : _hasText
                        ? _goldA.withOpacity(0.7)
                        : _textMuted,
                fontSize:   13,
                fontWeight: _isFocused || _hasText
                    ? FontWeight.w600
                    : FontWeight.w400,
                letterSpacing: 0.3,
              ),
              floatingLabelStyle: const TextStyle(
                color:         _goldA,
                fontSize:      12,
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.4,
              ),

              // ── Fill ────────────────────────────
              filled:    true,
              fillColor: _surface,

              // ── Prefix icon ─────────────────────
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  _prefixIcon(),
                  size: 18,
                  color: _isFocused
                      ? _goldA
                      : _textMuted.withOpacity(0.6),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth:  0,
                minHeight: 0,
              ),

              // ── Suffix — clear or check ──────────
              suffixIcon: _hasText
                  ? GestureDetector(
                      onTap: () => widget.controller.clear(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Icon(
                          _isFocused
                              ? Icons.close_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                          color: _isFocused
                              ? _textMuted
                              : _goldA.withOpacity(0.7),
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth:  0,
                minHeight: 0,
              ),

              // ── Padding ──────────────────────────
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical:   15,
              ),
              isDense: true,

              // ── Borders ──────────────────────────
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _border, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _hasText
                      ? _goldA.withOpacity(0.35)
                      : _border,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 1.2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _error.withOpacity(0.6),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _error.withOpacity(0.8),
                  width: 1.2,
                ),
              ),

              // ── Error style ──────────────────────
              errorStyle: TextStyle(
                color:         _error.withOpacity(0.85),
                fontSize:      11.5,
                letterSpacing: 0.2,
              ),

            ),
          ),
        );
      },
    );

    // ================= UI END =================
  }
}
