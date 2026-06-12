import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/voice_world_provider.dart';
// remove: voice_token_cache_provider import hataya — prefetch remove ho gaya
import '../../data/models/voice_group_model.dart';
import '../widgets/voice_world_header.dart';
import '../widgets/voice_search_bar.dart';
import '../widgets/voice_group_card.dart';
import '../widgets/voice_world_loading.dart';
import '../widgets/voice_world_error.dart';
import '../widgets/voice_world_empty.dart';
import 'voice_group_room_screen.dart';

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

  // remove: _prefetchDone field hataya — prefetch remove ho gaya
  bool _isNavigating = false;

  Future<void> _onJoinTapped(VoiceGroupModel group) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // modify: Fix #8 — Prefetch cache logic hataya
      // Pehle: cached token check → preloadedResult pass karta tha
      //        Lekin: world IDs jaate the (group IDs nahi) → sab fail
      //        Aur: joinGroup() DB records banata tha bina actual join ke
      // Ab: Seedha room screen push karo — normal join flow chalega
      //     ~1s ICE negotiation time save nahi ho sakta prefetch se anyway
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => VoiceGroupRoomScreen(
            group:           group,
            preloadedResult: null, // modify: hamesha null — normal join flow
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

    // remove: Prefetch block hataya
    // Pehle: state.worlds.map((w) => w.id) → world IDs (wrong!)
    //        repo.joinGroup() → DB records + ghost members
    // Ab: Kuch nahi — join tap pe normal flow

    final groups = state.filteredGroups;

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
