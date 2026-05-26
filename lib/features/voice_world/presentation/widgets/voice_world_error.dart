import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE WORLD ERROR
//  Path: lib/features/voice_world/presentation/widgets/voice_world_error.dart
// ─────────────────────────────────────────────────────────

class VoiceWorldError extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const VoiceWorldError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  static const _bg        = Color(0xFF0A0A0F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _textMuted = Color(0xFF55556A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  width:  64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.red.withOpacity(0.6),
                    size:  28,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Could not load worlds",
                  style: TextStyle(
                    color:       Colors.white,
                    fontSize:    16,
                    fontWeight:  FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Check your connection and try again",
                  style: TextStyle(
                    color:    _textMuted,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical:   12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [_goldA, _goldB],
                      ),
                    ),
                    child: const Text(
                      "Try Again",
                      style: TextStyle(
                        color:       Color(0xFF0A0A0F),
                        fontSize:    14,
                        fontWeight:  FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
