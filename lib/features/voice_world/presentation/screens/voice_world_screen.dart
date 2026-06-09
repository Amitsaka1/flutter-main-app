import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/voice_world_provider.dart';
import '../../../../providers/voice_token_cache_provider.dart'; // ✅ NEW
import '../../data/models/voice_group_model.dart';
import '../widgets/voice_world_header.dart';
import '../widgets/voice_search_bar.dart';
import '../widgets/voice_group_card.dart';
import '../widgets/voice_world_loading.dart';
import '../widgets/voice_world_error.dart';
import '../widgets/voice_world_empty.dart';
import 'voice_group_room_screen.dart';

// ─────────────────────────────────────────────────────────
//  VOICE WORLD SCREEN
//  Path: lib/features/voice_world/presentation/screens/voice_world_screen.dart
//  Sirf wiring — logic provider mein, UI widgets mein
// ─────────────────────────────────────────────────────────

class VoiceWorldScreen extends ConsumerStatefulWidget {
  const VoiceWorldScreen({super.key});

  @override
  ConsumerState<VoiceWorldScreen> createState() =>
      _VoiceWorldScreenState();
}

class _VoiceWorldScreenState
    extends ConsumerState<VoiceWorldScreen>
    with AutomaticKeepAliveClientMixin {

  static const _bg     = Color(0xFF0A0A0F);
  static const _goldA  = Color(0xFFD4A843);
  static const _border = Color(0xFF1E1E2E);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(voiceWorldProvider);
      if (state.status == VoiceWorldStatus.idle) {
        ref.read(voiceWorldProvider.notifier).fetchWorlds();
      }
    });
  }

  // FIX: Double tap protection — fast tap pe 2 rooms join hone se bachao
  bool _isNavigating = false;
  bool _prefetchDone  = false;

  Future<void> _onJoinTapped(VoiceGroupModel group) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // ✅ Cache check — instant token milega toh skip API call
      final cached = ref
          .read(voiceTokenCacheProvider.notifier)
          .getResult(group.id);

      // Cache se nikala toh hata do (use ho gaya)
      if (cached != null) {
        ref.read(voiceTokenCacheProvider.notifier).remove(group.id);
      }

      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => VoiceGroupRoomScreen(
            group:           group,
            preloadedResult: cached, // ✅ null ya instant token
          ),
        ),
      );

      ref.read(voiceWorldProvider.notifier).refresh();
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final state    = ref.watch(voiceWorldProvider);
    final notifier = ref.read(voiceWorldProvider.notifier);

    // ✅ Worlds load hone ke baad background mein tokens pre-fetch karo
    if (state.status == VoiceWorldStatus.loaded &&
        state.worlds.isNotEmpty &&
        !_prefetchDone) {
      _prefetchDone = true;
      final groupIds = state.worlds.map((w) => w.id).toList();
      ref.read(voiceTokenCacheProvider.notifier).prefetch(
        groupIds,
        ref.read(voiceWorldRepositoryProvider),
      );
    }
    final groups   = state.filteredGroups;

    if (state.status == VoiceWorldStatus.loading &&
        state.worlds.isEmpty) {
      return const VoiceWorldLoading();
    }

    if (state.status == VoiceWorldStatus.error &&
        state.worlds.isEmpty) {
      return VoiceWorldError(
        message: state.errorMessage ?? "Something went wrong",
        onRetry: notifier.refresh,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: _bg,
        child: SafeArea(
          child: Column(
            children: [

              const Padding(
                padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: VoiceWorldHeader(),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      _border,
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: VoiceSearchBar(
                  query:    state.searchQuery,
                  onChange: notifier.onSearchChanged,
                  onClear:  notifier.clearSearch,
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: _buildGrid(
                  groups:    groups,
                  isSearch:  state.searchQuery.isNotEmpty,
                  onRefresh: notifier.refresh,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid({
    required List<VoiceGroupModel>   groups,
    required bool                    isSearch,
    required Future<void> Function() onRefresh,
  }) {
    if (groups.isEmpty) {
      return VoiceWorldEmpty(isSearch: isSearch);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color:     _goldA,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.builder(
          physics:  const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   2,
            crossAxisSpacing: 12,
            mainAxisSpacing:  12,
            childAspectRatio: 0.82,
          ),
          itemCount: groups.length,
          itemBuilder: (_, i) => VoiceGroupCard(
            group:  groups[i],
            onJoin: () => _onJoinTapped(groups[i]),
          ),
        ),
      ),
    );
  }
}
