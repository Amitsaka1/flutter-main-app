import 'package:flutter/material.dart';
import '../../data/models/voice_group_model.dart';

// ─────────────────────────────────────────────────────────
//  VOICE MEMBER SHEET
//  Path: lib/features/voice_world/presentation/widgets/voice_member_sheet.dart
//  Long press pe bottom sheet — mute/report/gift options
// ─────────────────────────────────────────────────────────

class VoiceMemberSheet extends StatelessWidget {
  final VoiceMemberModel member;
  final bool             isLocalMuted;
  final bool             isBiMuted;
  final VoidCallback     onLocalMute;
  final VoidCallback     onBiMute;
  final VoidCallback     onGift;
  final VoidCallback     onReport;

  const VoiceMemberSheet({
    super.key,
    required this.member,
    required this.isLocalMuted,
    required this.isBiMuted,
    required this.onLocalMute,
    required this.onBiMute,
    required this.onGift,
    required this.onReport,
  });

  static const _bg        = Color(0xFF0E0E18);
  static const _surface   = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  // ── Show helper ───────────────────────────────────────
  static Future<void> show({
    required BuildContext         context,
    required VoiceMemberModel     member,
    required bool                 isLocalMuted,
    required bool                 isBiMuted,
    required VoidCallback         onLocalMute,
    required VoidCallback         onBiMute,
    required VoidCallback         onGift,
    required VoidCallback         onReport,
  }) {
    return showModalBottomSheet(
      context:           context,
      backgroundColor:   Colors.transparent,
      isScrollControlled: false,
      builder: (_) => VoiceMemberSheet(
        member:       member,
        isLocalMuted: isLocalMuted,
        isBiMuted:    isBiMuted,
        onLocalMute:  onLocalMute,
        onBiMute:     onBiMute,
        onGift:       onGift,
        onReport:     onReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = member.avatarUrl?.isNotEmpty == true;

    return Container(
      decoration: BoxDecoration(
        color:        _bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20)),
        border: Border.all(color: _border, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Drag handle
              Container(
                width:  36,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // ── Member info ──────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius:          24,
                    backgroundColor: _goldA.withOpacity(0.15),
                    backgroundImage: hasAvatar
                        ? NetworkImage(member.avatarUrl!)
                        : null,
                    child: hasAvatar
                        ? null
                        : Text(
                            (member.name?.isNotEmpty == true)
                                ? member.name![0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name ?? "User",
                        style: const TextStyle(
                          color:      _textPrime,
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "Level ${member.level} · ${member.isSpeaker ? "🎙️ Speaker" : "👂 Listener"}",
                        style: const TextStyle(
                          color:    _textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Divider(color: _border, height: 1),

              const SizedBox(height: 12),

              // ── Options ──────────────────────────

              // Local mute
              _SheetOption(
                icon:    isLocalMuted
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label:   isLocalMuted
                    ? "Unmute (only for me)"
                    : "Mute (only for me)",
                subtext: "Others won't be affected",
                onTap: () {
                  Navigator.pop(context);
                  onLocalMute();
                },
              ),

              const SizedBox(height: 4),

              // Bi-directional mute
              _SheetOption(
                icon:    isBiMuted
                    ? Icons.sync_rounded
                    : Icons.do_not_disturb_rounded,
                label:   isBiMuted
                    ? "Remove block"
                    : "Block both ways",
                subtext: "Neither of you will hear each other",
                isRed:   !isBiMuted,
                onTap: () {
                  Navigator.pop(context);
                  onBiMute();
                },
              ),

              const SizedBox(height: 4),

              // Gift
              _SheetOption(
                icon:    Icons.card_giftcard_rounded,
                label:   "Send Gift",
                subtext: "Show some love 🎁",
                isGold:  true,
                onTap: () {
                  Navigator.pop(context);
                  onGift();
                },
              ),

              const SizedBox(height: 4),

              // Report
              _SheetOption(
                icon:    Icons.flag_outlined,
                label:   "Report",
                subtext: "This person is behaving badly",
                isRed:   true,
                onTap: () {
                  Navigator.pop(context);
                  onReport();
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   subtext;
  final bool     isGold;
  final bool     isRed;
  final VoidCallback onTap;

  static const _surface   = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _border    = Color(0xFF1E1E2E);

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtext,
    required this.onTap,
    this.isGold = false,
    this.isRed  = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGold
        ? _goldA
        : isRed
            ? Colors.red.withOpacity(0.8)
            : _textPrime;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color:        _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isGold
                ? _goldA.withOpacity(0.15)
                : isRed
                    ? Colors.red.withOpacity(0.12)
                    : _border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color:      color,
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtext,
                    style: const TextStyle(
                      color:    _textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size:  16,
              color: _textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
