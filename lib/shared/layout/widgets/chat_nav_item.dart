import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CHAT NAV ITEM  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ChatNavItem extends StatefulWidget {
  final int          unreadCount;
  final bool         active;
  final VoidCallback onTap;

  const ChatNavItem({
    super.key,
    required this.unreadCount,
    required this.active,
    required this.onTap,
  });

  @override
  State<ChatNavItem> createState() => _ChatNavItemState();
}

class _ChatNavItemState extends State<ChatNavItem>
    with TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _goldA   = Color(0xFFD4A843);
  static const _goldB   = Color(0xFFE8C86A);
  static const _goldC   = Color(0xFFB8892E);
  static const _surface = Color(0xFF13131F);
  static const _border  = Color(0xFF2A2A3A);
  static const _muted   = Color(0xFF55556A);

  // ── Controllers ──────────────────────────────
  late AnimationController _badgeCtrl;   // badge pulse
  late AnimationController _iconCtrl;    // icon bounce on new message
  late AnimationController _activeCtrl;  // active glow

  late Animation<double> _badgePulse;
  late Animation<double> _badgeScale;
  late Animation<double> _iconBounce;
  late Animation<double> _activeGlow;

  int _prevUnread = 0;

  @override
  void initState() {
    super.initState();

    _prevUnread = widget.unreadCount;

    // Badge pulse — repeating
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _badgePulse = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeInOut),
    );

    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut),
    );

    if (widget.unreadCount > 0) {
      _badgeCtrl.repeat(reverse: true);
    }

    // Icon bounce on new message
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _iconBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut),
    );

    // Active glow
    _activeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _activeGlow = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _activeCtrl, curve: Curves.easeInOut),
    );

    if (widget.active) _activeCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ChatNavItem old) {
    super.didUpdateWidget(old);

    // New message arrived
    if (widget.unreadCount > old.unreadCount) {
      _iconCtrl
        ..reset()
        ..forward();
      _badgeCtrl.repeat(reverse: true);
    }

    // All read
    if (widget.unreadCount == 0 && old.unreadCount > 0) {
      _badgeCtrl.stop();
    }

    // Active state change
    if (widget.active && !old.active) {
      _activeCtrl.repeat(reverse: true);
    } else if (!widget.active && old.active) {
      _activeCtrl.stop();
      _activeCtrl.reset();
    }

    _prevUnread = widget.unreadCount;
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    _iconCtrl.dispose();
    _activeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    final bool hasUnread = widget.unreadCount > 0;
    final String badgeLabel = widget.unreadCount > 99
        ? "99+"
        : "${widget.unreadCount}";

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,

      child: AnimatedBuilder(
        animation: Listenable.merge([
          _badgeCtrl,
          _iconCtrl,
          _activeCtrl,
        ]),
        builder: (_, __) {

          return SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Icon + badge ────────────────────
                SizedBox(
                  width:  36,
                  height: 36,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [

                      // Active glow ring
                      if (widget.active)
                        Container(
                          width:  36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _goldA.withOpacity(
                                  _activeGlow.value * 0.25,
                                ),
                                blurRadius:   16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),

                      // Icon container
                      Transform.scale(
                        scale: _iconBounce.value,
                        child: Container(
                          width:  36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.active
                                ? _goldA.withOpacity(0.12)
                                : Colors.transparent,
                            border: widget.active
                                ? Border.all(
                                    color: _goldA.withOpacity(0.25),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: widget.active
                              ? ShaderMask(
                                  shaderCallback: (b) => const LinearGradient(
                                    colors: [_goldA, _goldB],
                                    begin:  Alignment.topLeft,
                                    end:    Alignment.bottomRight,
                                  ).createShader(b),
                                  child: Icon(
                                    hasUnread
                                        ? Icons.chat_bubble_rounded
                                        : Icons.chat_bubble_outline_rounded,
                                    size:  22,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  hasUnread
                                      ? Icons.chat_bubble_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  size:  22,
                                  color: hasUnread
                                      ? _goldA.withOpacity(0.7)
                                      : _muted,
                                ),
                        ),
                      ),

                      // ── Unread badge ──────────────
                      if (hasUnread)
                        Positioned(
                          top:   -4,
                          right: -6,
                          child: Transform.scale(
                            scale: _badgePulse.value,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth:  18,
                                minHeight: 18,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [_goldC, _goldA, _goldB],
                                  begin:  Alignment.topLeft,
                                  end:    Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _goldA.withOpacity(0.7),
                                    blurRadius:   8,
                                    spreadRadius: 0,
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFF0A0A0F),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  badgeLabel,
                                  style: const TextStyle(
                                    fontSize:      9.5,
                                    fontWeight:    FontWeight.w800,
                                    color:         Color(0xFF0A0A0F),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── Label ──────────────────────────
                widget.active
                    ? ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_goldA, _goldB],
                        ).createShader(b),
                        child: const Text(
                          "Chat",
                          style: TextStyle(
                            color:         Colors.white,
                            fontSize:      11,
                            fontWeight:    FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    : Text(
                        "Chat",
                        style: TextStyle(
                          color:         hasUnread
                              ? _goldA.withOpacity(0.65)
                              : _muted,
                          fontSize:      11,
                          fontWeight:    hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),

              ],
            ),
          );
        },
      ),
    );

    // ===================== UI END =======================
  }
}
