import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CHAT PANEL  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ChatPanel extends StatefulWidget {
  final List<String> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onClose;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
    required this.onClose,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel>
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

  final FocusNode _focus    = FocusNode();
  final ScrollController _scroll = ScrollController();

  late AnimationController _entranceCtrl;
  late Animation<double>   _slideUp;
  late Animation<double>   _fadeIn;

  bool _isFocused = false;
  bool _hasText   = false;

  @override
  void initState() {
    super.initState();

    // Panel slide-up entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _slideUp = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );

    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );

    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
    });

    widget.controller.addListener(() {
      final has = widget.controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Auto scroll to bottom on new message
  @override
  void didUpdateWidget(ChatPanel old) {
    super.didUpdateWidget(old);
    if (widget.messages.length != old.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ── Message bubble ────────────────────────────
  Widget _buildMessage(String text, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - val)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Avatar dot
            Container(
              width:  6,
              height: 6,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _goldA.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color:      _goldA.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            // Message text
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical:    8,
                ),
                decoration: BoxDecoration(
                  color:        _surfaceHi,
                  borderRadius: const BorderRadius.only(
                    topRight:    Radius.circular(14),
                    bottomLeft:  Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  border: Border.all(
                    color: _border,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color:         _textPrime,
                    fontSize:      13,
                    height:        1.4,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return FadeTransition(
      opacity: _fadeIn,
      child: AnimatedBuilder(
        animation: _slideUp,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),

            // ── Gradient border top ──────────────
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
                color:       Colors.black.withOpacity(0.6),
                blurRadius:  40,
                spreadRadius: -4,
                offset: const Offset(0, -8),
              ),
              BoxShadow(
                color:       _goldA.withOpacity(0.05),
                blurRadius:  60,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          padding: const EdgeInsets.only(
            left: 1.2, right: 1.2, bottom: 1.2,
          ),

          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D1A),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(23),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),

            child: Column(
              children: [

                // ── Drag handle ───────────────────
                Center(
                  child: Container(
                    width:  36,
                    height: 3.5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _border,
                    ),
                  ),
                ),

                // ── Header ────────────────────────
                Row(
                  children: [

                    // Icon
                    Container(
                      width:  32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accent.withOpacity(0.12),
                        border: Border.all(
                          color: _accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        size:  15,
                        color: Color(0xFF8B84FF),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Title
                    const Text(
                      "Live Chat",
                      style: TextStyle(
                        color:         _textPrime,
                        fontSize:      15,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const Spacer(),

                    // Close button
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width:  32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _surface,
                          border: Border.all(
                            color: _border,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size:  15,
                          color: _textMuted,
                        ),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 10),

                // ── Gold divider ──────────────────
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _goldA.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Messages list ─────────────────
                Expanded(
                  child: widget.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size:  32,
                                color: _textMuted.withOpacity(0.3),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No messages yet\nSay something!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:    _textMuted.withOpacity(0.5),
                                  fontSize: 12,
                                  height:   1.6,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller:  _scroll,
                          padding:     EdgeInsets.zero,
                          itemCount:   widget.messages.length,
                          itemBuilder: (_, index) =>
                              _buildMessage(widget.messages[index], index),
                        ),
                ),

                const SizedBox(height: 10),

                // ── Input row ─────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color:        _surfaceHi,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isFocused
                          ? _goldA.withOpacity(0.5)
                          : _border,
                      width: 1,
                    ),
                    boxShadow: _isFocused
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

                      // TextField
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode:  _focus,
                          style: const TextStyle(
                            color:         _textPrime,
                            fontSize:      13.5,
                            letterSpacing: 0.2,
                          ),
                          cursorColor: _goldA,
                          cursorWidth: 1.5,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: TextStyle(
                              color:    _textMuted,
                              fontSize: 13,
                            ),
                            border:         InputBorder.none,
                            isDense:        true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => widget.onSend(),
                        ),
                      ),

                      // Send button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: _hasText
                            ? GestureDetector(
                                key:   const ValueKey('send'),
                                onTap: widget.onSend,
                                child: Container(
                                  width:  34,
                                  height: 34,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [_goldC, _goldA, _goldB],
                                      begin:  Alignment.topLeft,
                                      end:    Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:       _goldA.withOpacity(0.45),
                                        blurRadius:  10,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.send_rounded,
                                    size:  15,
                                    color: Color(0xFF0A0A0F),
                                  ),
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey('empty'),
                                width: 0,
                              ),
                      ),

                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
