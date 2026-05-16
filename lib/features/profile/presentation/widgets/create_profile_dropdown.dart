import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CREATE PROFILE DROPDOWN  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class CreateProfileDropdown<T> extends StatefulWidget {
  final T?                        value;
  final String                    label;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)         onChanged;
  final String? Function(T?)?     validator;

  const CreateProfileDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    required this.validator,
  });

  @override
  State<CreateProfileDropdown<T>> createState() =>
      _CreateProfileDropdownState<T>();
}

class _CreateProfileDropdownState<T>
    extends State<CreateProfileDropdown<T>>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface    = Color(0xFF0E0E18);
  static const _surfaceAlt = Color(0xFF13131F);
  static const _goldA      = Color(0xFFD4A843);
  static const _goldB      = Color(0xFFE8C86A);
  static const _goldC      = Color(0xFFB8892E);
  static const _border     = Color(0xFF2A2A3A);
  static const _textPrime  = Color(0xFFF0EDE8);
  static const _textMuted  = Color(0xFF55556A);
  static const _error      = Color(0xFFE05C5C);

  late AnimationController _ctrl;
  late Animation<double>   _glowAnim;
  late Animation<double>   _arrowAnim;

  bool _isFocused = false;
  bool _hasError  = false;

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

    _arrowAnim = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    if (widget.value != null) _ctrl.forward();
  }

  @override
  void didUpdateWidget(CreateProfileDropdown<T> old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != null) {
      _ctrl.forward();
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

    final bool isSelected = widget.value != null;

    return FormField<T>(
      initialValue: widget.value,
      validator:    widget.validator,
      builder: (field) {
        _hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Dropdown shell ────────────────────
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final borderColor = _hasError
                    ? _error.withOpacity(0.6)
                    : isSelected
                        ? Color.lerp(_border, _goldA.withOpacity(0.6),
                            _glowAnim.value)!
                        : _border;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),

                    // ── Glow ──────────────────────
                    boxShadow: isSelected && !_hasError
                        ? [
                            BoxShadow(
                              color: _goldA.withOpacity(
                                _glowAnim.value * 0.12,
                              ),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : _hasError
                            ? [
                                BoxShadow(
                                  color: _error.withOpacity(0.08),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                  ),

                  child: Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor,
                        width: 1.0,
                      ),
                    ),

                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButtonFormField<T>(
                          value: widget.value,
                          isExpanded: true,

                          // ── Dropdown menu style ──────
                          dropdownColor: const Color(0xFF13131F),
                          menuMaxHeight: 260,

                          decoration: InputDecoration(
                            labelText: widget.label,
                            labelStyle: TextStyle(
                              color: isSelected ? _goldA : _textMuted,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: _goldA,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                            border:         InputBorder.none,
                            enabledBorder:  InputBorder.none,
                            focusedBorder:  InputBorder.none,
                            errorBorder:    InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            // Hide default error — custom below
                            errorStyle: const TextStyle(height: 0),
                          ),

                          // ── Arrow icon ───────────────
                          icon: RotationTransition(
                            turns: _arrowAnim,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: isSelected ? _goldA : _textMuted,
                            ),
                          ),

                          // ── Selected item style ──────
                          style: const TextStyle(
                            color: _textPrime,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),

                          // ── Items ────────────────────
                          items: widget.items.map((item) {
                            return DropdownMenuItem<T>(
                              value: item.value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    // Gold dot for selected
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width:  6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: item.value == widget.value
                                            ? _goldA
                                            : Colors.transparent,
                                        boxShadow: item.value == widget.value
                                            ? [
                                                BoxShadow(
                                                  color: _goldA.withOpacity(
                                                    0.6,
                                                  ),
                                                  blurRadius: 6,
                                                ),
                                              ]
                                            : [],
                                      ),
                                    ),
                                    DefaultTextStyle(
                                      style: TextStyle(
                                        color: item.value == widget.value
                                            ? _goldA
                                            : _textPrime,
                                        fontSize: 14,
                                        fontWeight: item.value == widget.value
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        letterSpacing: 0.3,
                                      ),
                                      child: item.child,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                          onChanged: (val) {
                            widget.onChanged(val);
                            field.didChange(val);
                            if (val != null) {
                              _ctrl.forward();
                            } else {
                              _ctrl.reverse();
                            }
                          },

                          validator: widget.validator,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Error message ─────────────────────
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 12,
                      color: _error.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      field.errorText ?? "",
                      style: TextStyle(
                        color: _error.withOpacity(0.85),
                        fontSize: 11.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

          ],
        );
      },
    );

    // ================= UI END =================
  }
}
