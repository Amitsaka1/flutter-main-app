import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE WORLD EMPTY
//  Path: lib/features/voice_world/presentation/widgets/voice_world_empty.dart
//  2 states — no groups, ya search no result
// ─────────────────────────────────────────────────────────

class VoiceWorldEmpty extends StatelessWidget {
  final bool isSearch;

  const VoiceWorldEmpty({
    super.key,
    this.isSearch = false,
  });

  static const _goldA     = Color(0xFFD4A843);
  static const _textMuted = Color(0xFF55556A);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Text(
              isSearch ? "🔍" : "🌍",
              style: const TextStyle(fontSize: 48),
            ),

            const SizedBox(height: 16),

            Text(
              isSearch
                  ? "No group found"
                  : "No worlds yet",
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isSearch
                  ? "Try a different Group ID"
                  : "Check back soon",
              style: TextStyle(
                color:    _textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }
}
