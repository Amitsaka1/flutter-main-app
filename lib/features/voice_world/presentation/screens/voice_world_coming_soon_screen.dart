import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE WORLD COMING SOON
//  Path: lib/features/voice_world/presentation/screens/
//        voice_world_coming_soon_screen.dart
//
//  Backend flag (VOICE_WORLD_ENABLED) off hone par yeh screen
//  dikhta hai. Route/tab same rehta hai — sirf content gate
//  hota hai (see VoiceWorldGate).
// ─────────────────────────────────────────────────────────

class VoiceWorldComingSoonScreen extends StatefulWidget {
  const VoiceWorldComingSoonScreen({super.key});

  @override
  State<VoiceWorldComingSoonScreen> createState() =>
      _VoiceWorldComingSoonScreenState();
}

class _VoiceWorldComingSoonScreenState
    extends State<VoiceWorldComingSoonScreen>
    with SingleTickerProviderStateMixin {

  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _textMuted = Color(0xFF55556A);

  late final AnimationController _glowCtrl;
  late final Animation<double>   _glow;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.22, end: 0.50).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

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

                // ── Glowing icon badge ──────────────────
                AnimatedBuilder(
                  animation: _glow,
                  builder: (_, __) => Container(
                    width:  96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _surface,
                      border: Border.all(
                        color: _goldA.withOpacity(0.5),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:        _goldA.withOpacity(_glow.value),
                          blurRadius:   28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: _goldA,
                      size:  40,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "Voice World",
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                // ── "Coming Soon" pill ──────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical:   6,
                  ),
                  decoration: BoxDecoration(
                    color:        _goldA.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _goldA.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    "COMING SOON",
                    style: TextStyle(
                      color:         _goldA,
                      fontSize:      11,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "We're putting the finishing touches on\nVoice World. Check back soon.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:    _textMuted,
                    fontSize: 13,
                    height:   1.5,
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
