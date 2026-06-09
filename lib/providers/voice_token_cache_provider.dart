import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/voice_world/data/models/voice_group_model.dart';
import '../features/voice_world/data/repository/voice_world_repository.dart';

// ─────────────────────────────────────────────────────────
//  VOICE TOKEN CACHE PROVIDER
//  Path: lib/providers/voice_token_cache_provider.dart
//
//  Worlds screen load hote hi background mein
//  top rooms ke tokens fetch karke yahan store karo
//  Join tap karne pe cache se instant token milega ⚡
// ─────────────────────────────────────────────────────────

final voiceTokenCacheProvider = StateNotifierProvider<
    VoiceTokenCacheNotifier,
    Map<String, VoiceJoinResult>>(
  (ref) => VoiceTokenCacheNotifier(),
);

class VoiceTokenCacheNotifier
    extends StateNotifier<Map<String, VoiceJoinResult>> {

  VoiceTokenCacheNotifier() : super({});

  bool _isFetching = false;

  // ── Background mein top rooms ke tokens fetch karo ──
  Future<void> prefetch(
    List<String>          groupIds,
    VoiceWorldRepository  repo,
  ) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      for (final groupId in groupIds.take(5)) {
        // Already cached hai toh skip karo
        if (state.containsKey(groupId)) continue;

        // Background fetch — error pe quietly skip karo
        repo.joinGroup(groupId).then((result) {
          state = { ...state, groupId: result };
        }).catchError((_) {
          // Pre-fetch fail hona ok hai
          // User join tap karega tab normal flow chalega
        });

        // Ek saath sab rooms flood mat karo server pe
        await Future.delayed(const Duration(milliseconds: 400));
      }
    } finally {
      _isFetching = false;
    }
  }

  // ── Token lo agar cached hai ─────────────────────────
  VoiceJoinResult? getResult(String groupId) => state[groupId];

  // ── Join ke baad cache hatao ─────────────────────────
  void remove(String groupId) {
    final updated = Map<String, VoiceJoinResult>.from(state);
    updated.remove(groupId);
    state = updated;
  }

  // ── Sab clear karo (logout/leave) ───────────────────
  void clearAll() => state = {};
}
