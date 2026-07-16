import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/voice_world_status_provider.dart';
import '../widgets/voice_world_loading.dart';
import 'voice_world_screen.dart';
import 'voice_world_coming_soon_screen.dart';

// ─────────────────────────────────────────────────────────
//  VOICE WORLD GATE
//  Path: lib/features/voice_world/presentation/screens/
//        voice_world_gate.dart
//
//  Backend feature-flag (VOICE_WORLD_ENABLED) check karta hai,
//  phir Active screen ya Coming Soon screen render karta hai.
//
//  app.dart ka /voice-world route ab seedha VoiceWorldScreen
//  ki jagah isi widget ko point karta hai.
//
//  NOTE: VoiceWorldScreen, VoiceWorldRepository, aur existing
//  VoiceWorldProvider (data state) bilkul touch nahi kiye gaye —
//  yeh sirf un sabke aage ek thin gate hai.
// ─────────────────────────────────────────────────────────

class VoiceWorldGate extends ConsumerWidget {
  const VoiceWorldGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(voiceWorldStatusProvider);

    return statusAsync.when(
      data: (enabled) => enabled
          ? const VoiceWorldScreen()
          : const VoiceWorldComingSoonScreen(),

      // Status check chal raha hai (halka call, fast) — existing
      // skeleton dikhao, real ya coming-soon content tab tak
      // mat dikhao jab tak pata na chale. Isse disabled hone
      // par real screen ka flash nahi dikhega.
      loading: () => const VoiceWorldLoading(),

      // Status fetch fail (network blip) — fail-open, real
      // screen dikhao taaki actual users feature se lock-out
      // na ho jayein kisi temporary glitch ki wajah se
      error: (_, __) => const VoiceWorldScreen(),
    );
  }
}
