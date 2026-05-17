import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CHAT CARD  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ChatCard extends StatefulWidget {
  final dynamic     chat;
  final VoidCallback onTap;

  const ChatCard({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _online    = Color(0xFF39E27A);

  late AnimationController _pressCtrl;
  late Animation<double>   _pressScale;
  late Animation<double>   _badgePulse;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );

    _badgePulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );

    final unread = widget.chat["unreadCount"] ?? 0;
    if (unread > 0) {
      _pressCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  // ── Avatar initials from phone ────────────────
  String _initials(String phone) {
    if (phone.length < 2) return phone;
    return phone.substring(phone.length - 2);
  }

  // ── Avatar gradient by phone hash ────────────
  List<Color> _avatarGradient(String phone) {
    final hash = phone.hashCode.abs();
    final gradients = [
      [const Color(0xFF6C63FF), const Color(0xFF4A42CC)],
      [const Color(0xFFD4A843), const Color(0xFFB8892E)],
      [const Color(0xFF39E27A), const Color(0xFF27AE60)],
      [const Color(0xFFE05C5C), const Color(0xFFB83A3A)],
      [const Color(0xFF5DADE2), const Color(0xFF2E86C1)],
    ];
    return gradients[hash % gradients.length]
        .map((c) => c)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    final unread      = widget.chat["unreadCount"] ?? 0;
    final phone       = widget.chat["user"]["phone"]?.toString() ?? "";
    final name        = widget.chat["user"]["name"]?.toString() ?? phone;
    final lastMessage = widget.chat["lastMessage"]?.toString() ?? "";
    final avatarUrl   = widget.chat["user"]["avatarUrl"]?.toString();
    final hasAvatar   = avatarUrl != null && avatarUrl.isNotEmpty;
    final bool hasUnread = unread > 0;
    final avatarColors = _avatarGradient(phone);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        if (!hasUnread) _pressCtrl.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!hasUnread) _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        if (!hasUnread) _pressCtrl.reverse();
      },

      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (_, child) => Transform.scale(
          scale: _isPressed ? _pressScale.value : 1.0,
          child: child,
        ),

        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical:   6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            // ── Gradient border shell ────────────
            gradient: LinearGradient(
              colors: hasUnread
                  ? [
                      _goldA.withOpacity(0.5),
                      _border,
                      _goldA.withOpacity(0.3),
                    ]
                  : [
                      _border,
                      const Color(0xFF181824),
                      _border,
                    ],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ),

            boxShadow: hasUnread
                ? [
                    BoxShadow(
                      color:       _goldA.withOpacity(0.10),
                      blurRadius:  20,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color:       Colors.black.withOpacity(0.2),
                      blurRadius:  10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(1.2),

          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical:   14,
            ),
            decoration: BoxDecoration(
              color:        _surfaceHi,
              borderRadius: BorderRadius.circular(17),
            ),

            child: Row(
              children: [

                // ── Avatar ───────────────────────────
                Container(
                  width:  50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape:    BoxShape.circle,
                    gradient: LinearGradient(
                      colors: avatarColors,
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ),
                    image: hasAvatar
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl!),
                            fit:   BoxFit.cover,
                          )
                        : null,
                    border: Border.all(
                      color: hasUnread
                          ? _goldA.withOpacity(0.4)
                          : _border,
                      width: 1.5,
                    ),
                    boxShadow: hasUnread
                        ? [
                            BoxShadow(
                              color:       _goldA.withOpacity(0.2),
                              blurRadius:  12,
                              spreadRadius: 0,
                            ),
                          ]
                        : [],
                  ),
                  child: hasAvatar
                      ? null
                      : Center(
                          child: Text(
                            _initials(phone),
                            style: const TextStyle(
                              color:         Colors.white,
                              fontSize:      14,
                              fontWeight:    FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),

                const SizedBox(width: 14),

                // ── Text content ─────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Name / phone
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:         hasUnread
                              ? _textPrime
                              : _textPrime.withOpacity(0.85),
                          fontSize:      14,
                          fontWeight:    hasUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Last message
                      Text(
                        lastMessage.isNotEmpty
                            ? lastMessage
                            : "Tap to start chatting",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:    hasUnread
                              ? _textMuted.withOpacity(0.9)
                              : _textMuted.withOpacity(0.6),
                          fontSize: 12.5,
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ── Unread badge ──────────────────────
                if (hasUnread)
                  AnimatedBuilder(
                    animation: _badgePulse,
                    builder: (_, __) => Transform.scale(
                      scale: _badgePulse.value,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth:  22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
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
                              color:       _goldA.withOpacity(0.6),
                              blurRadius:  10,
                              spreadRadius: 0,
                            ),
                          ],
                          border: Border.all(
                            color: _bg,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            unread > 99 ? "99+" : "$unread",
                            style: const TextStyle(
                              fontSize:      10,
                              fontWeight:    FontWeight.w800,
                              color:         Color(0xFF0A0A0F),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )

                // ── Arrow (no unread) ─────────────────
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size:  18,
                    color: _textMuted.withOpacity(0.3),
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
