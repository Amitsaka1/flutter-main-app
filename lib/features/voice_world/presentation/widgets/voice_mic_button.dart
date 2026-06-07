import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE MIC BUTTON
//  Path: lib/features/voice_world/presentation/widgets/voice_mic_button.dart
//  Speaker = mic toggle | Listener = listening label
// ─────────────────────────────────────────────────────────

class VoiceMicButton extends StatefulWidget {
  final bool         isSpeaker;
  final bool         isMicOn;
  final bool         isLoading;
  final VoidCallback onToggle;
  final VoidCallback onLeave;

  const VoiceMicButton({
    super.key,
    required this.isSpeaker,
    required this.isMicOn,
    required this.isLoading,
    required this.onToggle,
    required this.onLeave,
  });

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with SingleTickerProviderStateMixin {

  static const _goldA = Color(0xFFD4A843);
  static const _goldB = Color(0xFFE8C86A);

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceMicButton old) {
    super.didUpdateWidget(old);
    if (widget.isMicOn && widget.isSpeaker) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        // ── Leave button ─────────────────────────
        // FIX: Tooltip + Semantics — accessibility ke liye
        Tooltip(
          message: "Leave Room",
          child: Semantics(
            label:  "Leave voice room",
            button: true,
            child: GestureDetector(
              onTap: widget.onLeave,
              child: Container(
                width:  48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.red,
                  size:  20,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // ── Mic / Listener ───────────────────────
        if (!widget.isSpeaker)
          // Listener — sirf indicator
          _ListeningIndicator()
        else
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: widget.isMicOn ? _pulseAnim.value : 1.0,
              // FIX: Tooltip + Semantics — mic state bhi batao
              child: Tooltip(
                message: widget.isMicOn ? "Mute Mic" : "Unmute Mic",
                child: Semantics(
                  label:   widget.isMicOn
                      ? "Microphone on, tap to mute"
                      : "Microphone off, tap to unmute",
                  button:  true,
                  enabled: !widget.isLoading,
                  child: GestureDetector(
                    onTap: widget.isLoading ? null : widget.onToggle,
                    child: Container(
                  width:  64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.isMicOn
                        ? const LinearGradient(
                            colors: [_goldA, _goldB],
                            begin: Alignment.topLeft,
                            end:   Alignment.bottomRight,
                          )
                        : null,
                    color: widget.isMicOn
                        ? null
                        : Colors.red.withOpacity(0.12),
                    border: Border.all(
                      color: widget.isMicOn
                          ? _goldA.withOpacity(0.4)
                          : Colors.red.withOpacity(0.4),
                      width: 2,
                    ),
                    boxShadow: widget.isMicOn
                        ? [
                            BoxShadow(
                              color:       _goldA.withOpacity(0.35),
                              blurRadius:  20,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: widget.isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _goldA,
                        )
                      : Icon(
                          widget.isMicOn
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          size:  28,
                          color: widget.isMicOn
                              ? const Color(0xFF0A0A0F)
                              : Colors.red,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),

        const SizedBox(width: 24),

        // ── Spacer (symmetric layout) ────────────
        const SizedBox(width: 48, height: 48),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  LISTENING INDICATOR — Listener ke liye
// ─────────────────────────────────────────────────────────

class _ListeningIndicator extends StatefulWidget {
  @override
  State<_ListeningIndicator> createState() =>
      _ListeningIndicatorState();
}

class _ListeningIndicatorState extends State<_ListeningIndicator>
    with SingleTickerProviderStateMixin {

  static const _textMuted = Color(0xFF55556A);

  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
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
      animation: _anim,
      builder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.headphones_rounded,
            size:  32,
            color: _textMuted.withOpacity(_anim.value),
          ),
          const SizedBox(height: 4),
          Text(
            "Listening",
            style: TextStyle(
              color:    _textMuted.withOpacity(_anim.value),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
