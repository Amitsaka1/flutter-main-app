import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE RECONNECTING BANNER
//  Path: lib/features/voice_world/presentation/widgets/voice_reconnecting_banner.dart
//  Internet drop pe smoothly dikhta hai top pe
// ─────────────────────────────────────────────────────────

class VoiceReconnectingBanner extends StatefulWidget {
  final bool isVisible;
  const VoiceReconnectingBanner({super.key, required this.isVisible});

  @override
  State<VoiceReconnectingBanner> createState() =>
      _VoiceReconnectingBannerState();
}

class _VoiceReconnectingBannerState
    extends State<VoiceReconnectingBanner>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<Offset>   _slide;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void didUpdateWidget(VoiceReconnectingBanner old) {
    super.didUpdateWidget(old);
    if (widget.isVisible) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: 8, horizontal: 16),
          color: const Color(0xFFD4A843).withOpacity(0.12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width:  12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color:       const Color(0xFFD4A843).withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Reconnecting...",
                style: TextStyle(
                  color:    const Color(0xFFD4A843).withOpacity(0.8),
                  fontSize: 12,
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
