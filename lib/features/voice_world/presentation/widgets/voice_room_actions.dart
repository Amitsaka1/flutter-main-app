import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE ROOM ACTIONS
//  Path: lib/features/voice_world/presentation/widgets/voice_room_actions.dart
//  Chat / Gift / Report — bottom action row
// ─────────────────────────────────────────────────────────

class VoiceRoomActions extends StatelessWidget {
  final VoidCallback onChat;
  final VoidCallback onGift;
  final VoidCallback onReport;

  const VoiceRoomActions({
    super.key,
    required this.onChat,
    required this.onGift,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ActionBtn(
            icon:  Icons.chat_bubble_outline_rounded,
            label: "Chat",
            onTap: onChat,
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon:  Icons.card_giftcard_rounded,
            label: "Gift",
            onTap: onGift,
            isGold: true,
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon:  Icons.flag_outlined,
            label: "Report",
            onTap: onReport,
            isRed: true,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final bool         isGold;
  final bool         isRed;

  static const _surface   = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _textMuted = Color(0xFF55556A);
  static const _border    = Color(0xFF1E1E2E);

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isGold = false,
    this.isRed  = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGold
        ? _goldA
        : isRed
            ? Colors.red.withOpacity(0.7)
            : _textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:        _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isGold
                  ? _goldA.withOpacity(0.2)
                  : isRed
                      ? Colors.red.withOpacity(0.15)
                      : _border,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color:    color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
