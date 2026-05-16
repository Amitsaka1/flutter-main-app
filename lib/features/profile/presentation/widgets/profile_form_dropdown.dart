import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE FORM DROPDOWN  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileFormDropdown<T> extends StatefulWidget {
  final T?                        value;
  final String                    label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>          onChanged;

  const ProfileFormDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  State<ProfileFormDropdown<T>> createState() =>
      _ProfileFormDropdownState<T>();
}

class _ProfileFormDropdownState<T>
    extends State<ProfileFormDropdown<T>>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceAlt= Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  late AnimationController _ctrl;
  late Animation<double>   _glowAnim;
  late Animation<double>   _arrowAnim;

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

    // Pre-fill state
    if (widget.value != null) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(ProfileFormDropdown<T> old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      widget.value != null ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Prefix icon by label ──────────────────────
  IconData _prefixIcon() {
    final l = widget.label.toLowerCase();
    if (l.contains("gender")) return Icons.wc_rounded;
    if (l.contains("role"))   return Icons.category_outlined;
    return Icons.list_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    final bool isSelected = widget.value != null;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {

        final borderColor = isSelected
            ? Color.lerp(
                _border,
                _goldA.withOpacity(0.6),
                _glowAnim.value,
              )!
            : _border;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),

            // ── Glow on selected ─────────────────
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _goldA.withOpacity(
                        _glowAnim.value * 0.12,
                      ),
                      blurRadius: 18,
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
              child: DropdownButtonFormField<T>(
                value: widget.value,
                isExpanded: true,
                dropdownColor: _surfaceAlt,
                menuMaxHeight: 260,

                decoration: InputDecoration(

                  // ── Prefix icon ─────────────────
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      _prefixIcon(),
                      size: 18,
                      color: isSelected
                          ? _goldA.withOpacity(0.8)
                          : _textMuted.withOpacity(0.6),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth:  0,
                    minHeight: 0,
                  ),

                  // ── Label ───────────────────────
                  labelText: widget.label,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? _goldA.withOpacity(0.85)
                        : _textMuted,
                    fontSize:   13,
                    fontWeight: isSelected
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

                  // ── Borders ─────────────────────
                  border:        InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder:   InputBorder.none,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical:   15,
                  ),
                  isDense: true,

                  // Hide default error spacing
                  errorStyle: const TextStyle(height: 0),
                ),

                // ── Arrow icon ─────────────────────
                icon: RotationTransition(
                  turns: _arrowAnim,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size:  20,
                    color: isSelected ? _goldA : _textMuted,
                  ),
                ),

                // ── Selected text style ────────────
                style: const TextStyle(
                  color:         _textPrime,
                  fontSize:      14,
                  fontWeight:    FontWeight.w500,
                  letterSpacing: 0.3,
                ),

                // ── Menu items ─────────────────────
                items: widget.items.map((item) {
                  final bool isActive = item.value == widget.value;
                  return DropdownMenuItem<T>(
                    value: item.value,
                    child: Row(
                      children: [

                        // Gold dot for selected
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width:  6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? _goldA
                                : Colors.transparent,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: _goldA.withOpacity(0.6),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : [],
                          ),
                        ),

                        DefaultTextStyle(
                          style: TextStyle(
                            color: isActive ? _goldA : _textPrime,
                            fontSize:   14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                          child: item.child,
                        ),

                      ],
                    ),
                  );
                }).toList(),

                onChanged: (val) {
                  widget.onChanged(val);
                  val != null ? _ctrl.forward() : _ctrl.reverse();
                },
              ),
            ),
          ),
        );
      },
    );

    // ================= UI END =================
  }
}
