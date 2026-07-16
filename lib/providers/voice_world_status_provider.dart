import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/voice_world/data/repository/voice_world_repository.dart';

// ─────────────────────────────────────────────────────────
//  VOICE WORLD STATUS PROVIDER
//  Path: lib/providers/voice_world_status_provider.dart
//
//  Backend feature-flag (VOICE_WORLD_ENABLED) check karta hai.
//  VoiceWorldGate isse watch karke decide karta hai —
//  Active screen dikhana hai ya Coming Soon.
//
//  NOTE: VoiceWorldProvider (existing, world data ka state)
//  ko bilkul touch nahi kiya — yeh ek alag, chhota, independent
//  provider hai sirf is gate ke liye.
// ─────────────────────────────────────────────────────────

final voiceWorldStatusProvider = FutureProvider<bool>((ref) async {
  return VoiceWorldRepository.instance.getWorldStatus();
});
