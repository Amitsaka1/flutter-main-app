import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE WORLD HEADER
//  Path: lib/features/voice_world/presentation/widgets/voice_world_header.dart
//  Stateless — sirf UI, koi logic nahi
// ─────────────────────────────────────────────────────────

class VoiceWorldHeader extends StatelessWidget {
  const VoiceWorldHeader({super.key});

  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _textMuted = Color(0xFF55556A);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        // ── Globe icon ───────────────────────────
        Container(
          width:  38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_goldA, _goldC],
              begin:  Alignment.topLeft,
              end:    Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color:       _goldA.withOpacity(0.35),
                blurRadius:  12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.language_rounded,
            size:  20,
            color: Color(0xFF0A0A0F),
          ),
        ),

        const SizedBox(width: 12),

        // ── Title ────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_goldA, _goldB],
              ).createShader(b),
              child: const Text(
                "Voice World",
                style: TextStyle(
                  color:       Colors.white,
                  fontSize:    20,
                  fontWeight:  FontWeight.w800,
                  letterSpacing: 0.4,
                  height:      1.1,
                ),
              ),
            ),
            Text(
              "Join a group & start talking",
              style: TextStyle(
                color:       _textMuted,
                fontSize:    11,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),

        const Spacer(),

        // ── Live pulse indicator ─────────────────
        _LiveDot(),
      ],
    );
  }
}

// ── Animated live dot ─────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {

  static const _goldA = Color(0xFFD4A843);

  late AnimationController _ctrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _goldA.withOpacity(0.1),
          border: Border.all(
            color: _goldA.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _goldA.withOpacity(_pulse.value),
                boxShadow: [
                  BoxShadow(
                    color:       _goldA.withOpacity(_pulse.value * 0.6),
                    blurRadius:  6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              "LIVE",
              style: TextStyle(
                color:       _goldA,
                fontSize:    10,
                fontWeight:  FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
