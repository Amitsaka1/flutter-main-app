import 'package:flutter/material.dart';
import '../../data/models/voice_group_model.dart';
import 'voice_seat_tile.dart';

// ─────────────────────────────────────────────────────────
//  VOICE SEAT GRID
//  Path: lib/features/voice_world/presentation/widgets/voice_seat_grid.dart
//  16 seats — 4x4 — responsive, no scroll
// ─────────────────────────────────────────────────────────

class VoiceSeatGrid extends StatelessWidget {
  final List<VoiceMemberModel> members;       // Current speakers (max 16)
  final Set<String>            activeSpeakers; // LiveKit active speakers
  final Map<String, bool>      localMuted;
  final Set<String>            biMuted;
  final String?                myUserId;
  final void Function(VoiceMemberModel) onMemberLongPress;

  const VoiceSeatGrid({
    super.key,
    required this.members,
    required this.activeSpeakers,
    required this.localMuted,
    required this.biMuted,
    required this.myUserId,
    required this.onMemberLongPress,
  });

  static const int _totalSeats = 16;
  static const int _cols       = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        // ── Responsive size calculation ───────────
        // Available width → seat size
        // Padding 12 on each side, spacing 10 between
        final totalPadding  = 24.0;                        // 12+12
        final totalSpacing  = 10.0 * (_cols - 1);          // 3 gaps
        final seatWidth     = (constraints.maxWidth -
            totalPadding - totalSpacing) / _cols;

        // Seat = circle + name + level
        // Name+level ~38px below circle
        final nameHeight    = 38.0;
        final tileHeight    = seatWidth + nameHeight;

        // 4 rows + 3 row gaps
        final rowSpacing    = 10.0;
        final gridHeight    = (tileHeight * 4) + (rowSpacing * 3);

        return SizedBox(
          height: gridHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (row) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: row < 3 ? rowSpacing : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (col) {
                      final index  = row * 4 + col;
                      final member = index < members.length
                          ? members[index]
                          : null;

                      return SizedBox(
                        width: seatWidth,
                        child: VoiceSeatTile(
                          member: member,
                          isSpeaking: member != null &&
                              activeSpeakers.contains(member.userId),
                          isLocalMuted: member != null &&
                              (localMuted[member.userId] == true),
                          isBiMuted: member != null &&
                              biMuted.contains(member.userId),
                          isMe: member?.userId == myUserId,
                          onLongPress: member != null
                              ? () => onMemberLongPress(member)
                              : null,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
