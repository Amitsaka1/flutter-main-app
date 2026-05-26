import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE LISTENER BAR
//  Path: lib/features/voice_world/presentation/widgets/voice_listener_bar.dart
// ─────────────────────────────────────────────────────────

class VoiceListenerBar extends StatelessWidget {
  final int listenerCount;
  const VoiceListenerBar({super.key, required this.listenerCount});

  static const _surface   = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _textMuted = Color(0xFF55556A);
  static const _border    = Color(0xFF1E1E2E);

  String get _label {
    if (listenerCount == 0) return "No listeners yet";
    if (listenerCount == 1) return "1 person listening";
    return "$listenerCount people listening";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.headphones_rounded,
            size:  15,
            color: _textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            _label,
            style: TextStyle(
              color:    _textMuted,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          if (listenerCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color:        _goldA.withOpacity(0.08),
              ),
              child: Text(
                "👂 $listenerCount",
                style: TextStyle(
                  color:    _goldA,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
