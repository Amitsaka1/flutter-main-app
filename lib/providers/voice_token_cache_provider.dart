import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/voice_world/data/models/voice_group_model.dart';
import '../features/voice_world/data/repository/voice_world_repository.dart';

// ─────────────────────────────────────────────────────────
//  VOICE TOKEN CACHE PROVIDER
//  Path: lib/providers/voice_token_cache_provider.dart
//
//  NOTE: Prefetch feature removed — Fix #8
//        joinGroup() DB side effects ki wajah se ghost members bante the
//        ICE negotiation (~950ms) save nahi ho sakta tha anyway
//        File structure rakha hai future use ke liye
// ─────────────────────────────────────────────────────────

final voiceTokenCacheProvider = StateNotifierProvider<
    VoiceTokenCacheNotifier,
    Map<String, VoiceJoinResult>>(
  (ref) => VoiceTokenCacheNotifier(),
);

class VoiceTokenCacheNotifier
    extends StateNotifier<Map<String, VoiceJoinResult>> {

  VoiceTokenCacheNotifier() : super({});

  // modify: Fix #8 — prefetch body hataya
  // Pehle: repo.joinGroup() call karta tha background mein
  //        Ghost DB members bante the + world IDs jaate the (wrong)
  // Ab: No-op — screen se call hona bhi band ho gaya
  Future<void> prefetch(
    List<String>         groupIds,
    VoiceWorldRepository repo,
  ) async {
    // Intentionally empty — prefetch removed
    // Direct join flow use karo
  }

  // unchanged: Cache operations — future use ke liye rakhe
  VoiceJoinResult? getResult(String groupId) => state[groupId];

  void remove(String groupId) {
    final updated = Map<String, VoiceJoinResult>.from(state);
    updated.remove(groupId);
    state = updated;
  }

  void clearAll() => state = {};
}
