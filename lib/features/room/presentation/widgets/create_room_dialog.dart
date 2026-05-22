import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CREATE ROOM DIALOG  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class CreateRoomDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final Future<void> Function() onStart;

  const CreateRoomDialog({
    super.key,
    required this.nameController,
    required this.descController,
    required this.onStart,
  });

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _accent    = Color(0xFF6C63FF);

  late AnimationController _entranceCtrl;
  late Animation<double>   _scaleIn;
  late Animation<double>   _fadeIn;

  bool _loading        = false;
  bool _nameFocused    = false;
  bool _descFocused    = false;
  bool _nameHasText    = false;
  bool _descHasText    = false;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Dialog entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();

    _scaleIn = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack),
    );

    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );

    _nameFocus.addListener(() {
      setState(() => _nameFocused = _nameFocus.hasFocus);
    });

    _descFocus.addListener(() {
      setState(() => _descFocused = _descFocus.hasFocus);
    });

    widget.nameController.addListener(() {
      final has = widget.nameController.text.isNotEmpty;
      if (has != _nameHasText) setState(() => _nameHasText = has);
    });

    widget.descController.addListener(() {
      final has = widget.descController.text.isNotEmpty;
      if (has != _descHasText) setState(() => _descHasText = has);
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  // ── Styled text field ─────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required FocusNode             focusNode,
    required bool                  isFocused,
    required bool                  hasText,
    required String                hint,
    required IconData              icon,
    bool                           isLast = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color:        _surfaceHi,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? _goldA.withOpacity(0.6)
              : hasText
                  ? _goldA.withOpacity(0.3)
                  : _border,
          width: 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color:       _goldA.withOpacity(0.10),
                  blurRadius:  16,
                  spreadRadius: -1,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical:    4,
      ),
      child: Row(
        children: [

          // Prefix icon
          Icon(
            icon,
            size:  17,
            color: isFocused
                ? _goldA
                : _textMuted.withOpacity(0.55),
          ),

          const SizedBox(width: 10),

          // Field
          Expanded(
            child: TextField(
              controller:  controller,
              focusNode:   focusNode,
              cursorColor: _goldA,
              cursorWidth: 1.5,
              style: const TextStyle(
                color:         _textPrime,
                fontSize:      14,
                letterSpacing: 0.2,
              ),
              textInputAction: isLast
                  ? TextInputAction.done
                  : TextInputAction.next,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color:    _textMuted,
                  fontSize: 13.5,
                ),
                border:         InputBorder.none,
                isDense:        true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Check when filled
          if (hasText)
            Icon(
              Icons.check_circle_outline_rounded,
              size:  16,
              color: _goldA.withOpacity(0.6),
            ),

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return FadeTransition(
      opacity: _fadeIn,
      child: AnimatedBuilder(
        animation: _scaleIn,
        builder: (_, child) => Transform.scale(
          scale: _scaleIn.value,
          child: child,
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation:       0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),

              // ── Gradient border shell ──────────
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
                  blurRadius:  40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color:       _goldA.withOpacity(0.06),
                  blurRadius:  60,
                  spreadRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.2),

            child: Container(
              decoration: BoxDecoration(
                color:        const Color(0xFF0D0D1A),
                borderRadius: BorderRadius.circular(23),
              ),
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Icon ──────────────────────────
                  Container(
                    width:  60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_goldC, _goldA, _goldB],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:       _goldA.withOpacity(0.4),
                          blurRadius:  20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.meeting_room_rounded,
                      size:  28,
                      color: Color(0xFF0A0A0F),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Title ─────────────────────────
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [_goldA, _goldB],
                    ).createShader(b),
                    child: const Text(
                      "Start a Room",
                      style: TextStyle(
                        color:         Colors.white,
                        fontSize:      20,
                        fontWeight:    FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Set up your live room",
                    style: TextStyle(
                      color:    _textMuted,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Gold divider ──────────────────
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _goldA.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Room name field ───────────────
                  _buildField(
                    controller: widget.nameController,
                    focusNode:  _nameFocus,
                    isFocused:  _nameFocused,
                    hasText:    _nameHasText,
                    hint:       "Room name",
                    icon:       Icons.meeting_room_outlined,
                  ),

                  const SizedBox(height: 12),

                  // ── Description field ─────────────
                  _buildField(
                    controller: widget.descController,
                    focusNode:  _descFocus,
                    isFocused:  _descFocused,
                    hasText:    _descHasText,
                    hint:       "Description (optional)",
                    icon:       Icons.notes_rounded,
                    isLast:     true,
                  ),

                  const SizedBox(height: 24),

                  // ── Action buttons ────────────────
                  Row(
                    children: [

                      // Cancel
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color:        _surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _border,
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color:         _textMuted,
                                  fontSize:      14,
                                  fontWeight:    FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Start button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _loading
                              ? null
                              : () async {
                                  setState(() => _loading = true);
                                  await widget.onStart();
                                  if (mounted) {
                                    setState(() => _loading = false);
                                  }
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: _loading
                                  ? LinearGradient(
                                      colors: [
                                        _goldC.withOpacity(0.5),
                                        _goldA.withOpacity(0.4),
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [_goldC, _goldA, _goldB],
                                      begin:  Alignment.topLeft,
                                      end:    Alignment.bottomRight,
                                    ),
                              boxShadow: _loading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color:       _goldA.withOpacity(0.4),
                                        blurRadius:  16,
                                        spreadRadius: -2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: _loading
                                  ? SizedBox(
                                      width:  18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          _bg.withOpacity(0.6),
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_arrow_rounded,
                                          size:  18,
                                          color: Color(0xFF0A0A0F),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Start Room",
                                          style: TextStyle(
                                            color:         Color(0xFF0A0A0F),
                                            fontSize:      14,
                                            fontWeight:    FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
