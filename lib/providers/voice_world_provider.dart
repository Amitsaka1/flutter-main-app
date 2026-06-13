import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/voice_world/data/models/voice_group_model.dart';
import '../features/voice_world/data/repository/voice_world_repository.dart';

import '../../../core/livekit/livekit_service.dart';
import '../../../core/session/user_session.dart';

// ─────────────────────────────────────────────────────────
//  VOICE CHAT MESSAGE MODEL — unchanged
// ─────────────────────────────────────────────────────────

class VoiceChatMessage {
  final String   userId;
  final String   name;
  final String?  avatarUrl;
  final String   message;
  final DateTime time;
  final bool     isMe;

  const VoiceChatMessage({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.message,
    required this.time,
    required this.isMe,
  });
}

// ─────────────────────────────────────────────────────────
//  ENUMS + STATES — unchanged
// ─────────────────────────────────────────────────────────

enum VoiceWorldStatus { idle, loading, loaded, error }
enum VoiceJoinStatus  { idle, joining, joined, leaving, error }

class VoiceWorldState {
  final VoiceWorldStatus      status;
  final List<VoiceWorldModel> worlds;
  final String?               errorMessage;
  final String                searchQuery;

  const VoiceWorldState({
    this.status       = VoiceWorldStatus.idle,
    this.worlds       = const [],
    this.errorMessage,
    this.searchQuery  = "",
  });

  List<VoiceGroupModel> get filteredGroups {
    if (worlds.isEmpty) return [];
    final all = worlds.expand((w) => w.groups).toList();
    if (searchQuery.trim().isEmpty) return all;
    return all
        .where((g) => g.shortId
            .toUpperCase()
            .contains(searchQuery.trim().toUpperCase()))
        .toList();
  }

  VoiceWorldState copyWith({
    VoiceWorldStatus?      status,
    List<VoiceWorldModel>? worlds,
    String?                errorMessage,
    String?                searchQuery,
  }) {
    return VoiceWorldState(
      status:       status       ?? this.status,
      worlds:       worlds       ?? this.worlds,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery:  searchQuery  ?? this.searchQuery,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  VOICE WORLD NOTIFIER — unchanged
// ─────────────────────────────────────────────────────────

class VoiceWorldNotifier extends StateNotifier<VoiceWorldState> {

  final VoiceWorldRepository _repo;

  VoiceWorldNotifier(this._repo) : super(const VoiceWorldState());

  Future<void> fetchWorlds() async {
    state = state.copyWith(status: VoiceWorldStatus.loading);
    try {
      final worlds = await _repo.getWorlds();
      state = state.copyWith(status: VoiceWorldStatus.loaded, worlds: worlds);
    } catch (e) {
      state = state.copyWith(
        status:       VoiceWorldStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void onSearchChanged(String query) =>
      state = state.copyWith(searchQuery: query);

  void clearSearch() => state = state.copyWith(searchQuery: "");

  Future<void> refresh() => fetchWorlds();
}

// ─────────────────────────────────────────────────────────
//  VOICE ROOM STATE — unchanged
// ─────────────────────────────────────────────────────────

class VoiceRoomState {
  final VoiceJoinStatus        joinStatus;
  final String?                errorMessage;
  final String?                myRole;
  final bool                   isMicOn;
  final List<VoiceMemberModel> members;
  final Map<String, bool>      localMutedUsers;
  final Set<String>            biMutedUsers;
  final bool                   isReconnecting;
  final bool                   justPromoted;
  final Set<String>            activeSpeakers;
  final int                    speakerCount;
  final int                    listenerCount;
  final List<VoiceChatMessage> chatMessages;
  final List<VoiceMemberModel> listeners;

  const VoiceRoomState({
    this.joinStatus       = VoiceJoinStatus.idle,
    this.errorMessage,
    this.myRole,
    this.isMicOn          = false,
    this.members          = const [],
    this.localMutedUsers  = const {},
    this.biMutedUsers     = const {},
    this.isReconnecting   = false,
    this.justPromoted     = false,
    this.activeSpeakers   = const {},
    this.speakerCount     = 0,
    this.listenerCount    = 0,
    this.chatMessages     = const [],
    this.listeners        = const [],
  });

  bool get isSpeaker  => myRole == "speaker";
  bool get isListener => myRole == "listener";
  bool get isJoined   => joinStatus == VoiceJoinStatus.joined;

  bool isLocalMuted(String userId) => localMutedUsers[userId] == true;
  bool isBiMuted(String userId)    => biMutedUsers.contains(userId);

  VoiceRoomState copyWith({
    VoiceJoinStatus?         joinStatus,
    String?                  errorMessage,
    String?                  myRole,
    bool?                    isMicOn,
    List<VoiceMemberModel>?  members,
    Map<String, bool>?       localMutedUsers,
    Set<String>?             biMutedUsers,
    bool?                    isReconnecting,
    bool?                    justPromoted,
    Set<String>?             activeSpeakers,
    int?                     speakerCount,
    int?                     listenerCount,
    List<VoiceChatMessage>?  chatMessages,
    List<VoiceMemberModel>?  listeners,
  }) {
    return VoiceRoomState(
      joinStatus:      joinStatus      ?? this.joinStatus,
      errorMessage:    errorMessage    ?? this.errorMessage,
      myRole:          myRole          ?? this.myRole,
      isMicOn:         isMicOn         ?? this.isMicOn,
      members:         members         ?? this.members,
      localMutedUsers: localMutedUsers ?? this.localMutedUsers,
      biMutedUsers:    biMutedUsers    ?? this.biMutedUsers,
      isReconnecting:  isReconnecting  ?? this.isReconnecting,
      justPromoted:    justPromoted    ?? this.justPromoted,
      activeSpeakers:  activeSpeakers  ?? this.activeSpeakers,
      speakerCount:    speakerCount    ?? this.speakerCount,
      listenerCount:   listenerCount   ?? this.listenerCount,
      chatMessages:    chatMessages    ?? this.chatMessages,
      listeners:       listeners       ?? this.listeners,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  VOICE ROOM NOTIFIER
// ─────────────────────────────────────────────────────────

class VoiceRoomNotifier extends StateNotifier<VoiceRoomState> {

  final VoiceWorldRepository _repo;
  final LiveKitService       _liveKit;

  dynamic  _roomListener;
  String?  _currentGroupId;
  bool     _cleanedUp = false;

  // modify: Constructor — Fix #3: onReconnected callback register karo
  // livekit_mobile.dart mein naya field tha jo reconnect success pe fire karta hai
  // Ab VoiceRoomNotifier ko pata chalega jab reconnect hua
  VoiceRoomNotifier(this._repo, this._liveKit)
      : super(const VoiceRoomState()) {
    _liveKit.onReconnected = _onLiveKitReconnected; // new: Fix #3
  }

  // ── JOIN ─────────────────────────────────────────────
  Future<void> joinGroup(VoiceGroupModel group) async {
    if (state.joinStatus == VoiceJoinStatus.joining) return;

    state = state.copyWith(joinStatus: VoiceJoinStatus.joining);

    try {
      final result = await _repo.joinGroup(group.id);

      _liveKit.reset();
      await _liveKit.connectWithToken(
        token:  result.token,
        roomId: "vg-${group.id}",
        role:   result.role,
      );

      _currentGroupId = group.id;
      _setupRoomListeners();

      final myId = UserSession.userId ?? "";

      final placeholder = VoiceMemberModel(
        userId:    myId,
        role:      result.role,
        isMuted:   false,
        name:      UserSession.name,
        avatarUrl: UserSession.avatarUrl,
        level:     UserSession.level,
      );

      final existingSpeakers  = group.members.where((m) => m.isSpeaker).toList();
      final existingListeners = group.members.where((m) => !m.isSpeaker).toList();
      final alreadyIn         = group.members.any((m) => m.userId == myId);

      final updatedSpeakers = (result.role == 'speaker' && !alreadyIn)
          ? [placeholder, ...existingSpeakers]
          : existingSpeakers;

      final updatedListeners = (result.role == 'listener' && !alreadyIn)
          ? [placeholder, ...existingListeners]
          : existingListeners;

      state = state.copyWith(
        joinStatus:    VoiceJoinStatus.joined,
        myRole:        result.role,
        isMicOn:       result.isSpeaker,
        members:       updatedSpeakers,
        listeners:     updatedListeners,
        speakerCount:  group.speakerCount,
        listenerCount: group.listenerCount,
      );

    } catch (e) {
      // modify: Fix #4 — Ghost seat prevent karo
      // Pehle: sirf joinStatus + errorMessage set hota tha
      // Ab: members + listeners bhi clear karo
      //     LiveKit bhi cleanup karo (agar partially connected tha)
      _liveKit.disconnect(
        expectedRoomId: "vg-${group.id}",
      ).catchError((_) {}); // new: Fix #4

      state = state.copyWith(
        joinStatus:    VoiceJoinStatus.error,
        errorMessage:  e.toString(),
        members:       [],        // new: Fix #4
        listeners:     [],        // new: Fix #4
        speakerCount:  0,         // new: Fix #4
        listenerCount: 0,         // new: Fix #4
      );
    }
  }

  // ─────────────────────────────────────────────────────
  //  JOIN WITH PRE-FETCHED TOKEN
  //  NOTE: Prefetch feature Step 6 mein remove hoga
  //        Tab tak ye method rakhna zaroori hai
  // ─────────────────────────────────────────────────────

  Future<void> joinGroupWithToken(
    VoiceGroupModel group,
    VoiceJoinResult result,
  ) async {
    if (state.joinStatus == VoiceJoinStatus.joining) return;
    state = state.copyWith(joinStatus: VoiceJoinStatus.joining);

    try {
      _liveKit.reset();
      await _liveKit.connectWithToken(
        token:  result.token,
        roomId: "vg-${group.id}",
        role:   result.role,
      );

      _currentGroupId = group.id;
      _setupRoomListeners();

      final myId          = UserSession.userId ?? "";
      final placeholder   = VoiceMemberModel(
        userId:    myId,
        role:      result.role,
        isMuted:   false,
        name:      UserSession.name,
        avatarUrl: UserSession.avatarUrl,
        level:     UserSession.level,
      );

      final existingSpeakers  = group.members.where((m) => m.isSpeaker).toList();
      final existingListeners = group.members.where((m) => !m.isSpeaker).toList();
      final alreadyIn         = group.members.any((m) => m.userId == myId);

      final updatedSpeakers = (result.role == 'speaker' && !alreadyIn)
          ? [placeholder, ...existingSpeakers]
          : existingSpeakers;

      final updatedListeners = (result.role == 'listener' && !alreadyIn)
          ? [placeholder, ...existingListeners]
          : existingListeners;

      state = state.copyWith(
        joinStatus:    VoiceJoinStatus.joined,
        myRole:        result.role,
        isMicOn:       result.isSpeaker,
        members:       updatedSpeakers,
        listeners:     updatedListeners,
        speakerCount:  group.speakerCount,
        listenerCount: group.listenerCount,
      );

    } catch (e) {
      // modify: Fix #4 — same ghost seat fix
      _liveKit.disconnect(
        expectedRoomId: "vg-${group.id}",
      ).catchError((_) {}); // new: Fix #4

      state = state.copyWith(
        joinStatus:    VoiceJoinStatus.error,
        errorMessage:  e.toString(),
        members:       [],     // new: Fix #4
        listeners:     [],     // new: Fix #4
        speakerCount:  0,      // new: Fix #4
        listenerCount: 0,      // new: Fix #4
      );
    }
  }

  // ── LEAVE ────────────────────────────────────────────
  Future<void> leaveGroup(String groupId) async {
    if (_cleanedUp) return;
    _cleanedUp = true;

    state = state.copyWith(
      joinStatus: VoiceJoinStatus.leaving,
      members:    [],
      listeners:  [],
    );

    // modify: Fix #6 — expectedRoomId pass karo
    // Pehle: _liveKit.disconnect() — koi bhi room disconnect ho sakta tha
    // Ab: Sirf is specific room ka disconnect hoga
    _liveKit.onReconnected = null;              // new: Fix #6 — reconnect callback clear
    _liveKit.disconnect(
      expectedRoomId: "vg-$groupId",           // new: Fix #5
    ).catchError((_) {});

    _repo.leaveGroupWithRetry(groupId);

    _roomListener?.dispose();
    _roomListener   = null;
    _currentGroupId = null;

    state = const VoiceRoomState();
  }

  // ── MIC CONTROLS — unchanged ─────────────────────────
  Future<void> toggleMic() async {
    if (!state.isSpeaker) return;
    final newMicState = !state.isMicOn;
    await _liveKit.toggleMic();
    state = state.copyWith(isMicOn: newMicState);
  }

  void toggleLocalMute(String userId) {
    final updated = Map<String, bool>.from(state.localMutedUsers);
    updated[userId] = !(updated[userId] == true);
    _applyTrackMute(userId, updated[userId]!);
    state = state.copyWith(localMutedUsers: updated);
  }

  void toggleBiMute(String userId) {
    final updated = Set<String>.from(state.biMutedUsers);
    if (updated.contains(userId)) {
      updated.remove(userId);
      _applyTrackMute(userId, false);
      _sendData("BI_UNMUTE:$userId");
    } else {
      updated.add(userId);
      _applyTrackMute(userId, true);
      _sendData("BI_MUTE:$userId");
    }
    state = state.copyWith(biMutedUsers: updated);
  }

  Future<void> reportUser({
    required String reportedId,
    required String groupId,
    required String reason,
  }) async {
    await _repo.reportUser(
      reportedId: reportedId,
      groupId:    groupId,
      reason:     reason,
    );
  }

  void clearPromoted() =>
      state = state.copyWith(justPromoted: false);

  void sendChatMessage(String message) {
    if (message.trim().isEmpty) return;

    final myId = UserSession.userId ?? "";

    final me = state.members.firstWhere(
      (m) => m.userId == myId,
      orElse: () => state.listeners.firstWhere(
        (m) => m.userId == myId,
        orElse: () => VoiceMemberModel(
          userId:    myId,
          role:      'listener',
          isMuted:   false,
          name:      UserSession.name,
          avatarUrl: UserSession.avatarUrl,
          level:     UserSession.level,
        ),
      ),
    );

    final chatMsg = VoiceChatMessage(
      userId:    myId,
      name:      me.name ?? "User",
      avatarUrl: me.avatarUrl,
      message:   message.trim(),
      time:      DateTime.now(),
      isMe:      true,
    );

    final updated = [...state.chatMessages, chatMsg];
    if (updated.length > 100) updated.removeAt(0);
    state = state.copyWith(chatMessages: updated);

    final payload = jsonEncode({
      "type":      "ROOM_CHAT",
      "userId":    myId,
      "name":      me.name      ?? "User",
      "avatarUrl": me.avatarUrl,
      "message":   message.trim(),
      "time":      DateTime.now().toIso8601String(),
    });

    _sendData("ROOM_CHAT:$payload");
  }

  // ─────────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ─────────────────────────────────────────────────────

  void _setupRoomListeners() {
    try {
      final room = _liveKit.room;
      if (room == null) return;

      _roomListener?.dispose();
      _roomListener = room.createListener();

      _roomListener
        ..on<dynamic>((event) {
          final name = event.runtimeType.toString();

          if (name.contains('ActiveSpeakersChangedEvent')) {
            try {
              final speakers = (event.speakers as List)
                  .map<String>((s) => s.identity as String)
                  .toSet();
              state = state.copyWith(activeSpeakers: speakers);
            } catch (_) {}
          }

          else if (name.contains('RoomReconnectingEvent')) {
            state = state.copyWith(isReconnecting: true);
          }

          else if (name.contains('RoomReconnectedEvent')) {
            // SDK internal reconnect — short hiccup
            state = state.copyWith(isReconnecting: false);

            if (_currentGroupId != null) {
              _repo.fetchGroupMembers(_currentGroupId!).then((result) {
                if (_cleanedUp || result == null) return;
                state = state.copyWith(
                  members:       result.speakers,
                  listeners:     result.listeners,
                  speakerCount:  result.speakerCount,
                  listenerCount: result.listenerCount,
                );
              }).catchError((_) {});
            }
          }

          // new: Fix #1 — RoomDisconnectedEvent pe banner reset karo
          // Pehle: ye handler tha hi nahi
          //        isReconnecting kabhi false nahi hota tha
          //        Banner hamesha ke liye stuck rehta tha
          // Ab: Full disconnect pe banner band karo
          //     _scheduleReconnect background mein chalega
          //     _onLiveKitReconnected callback success pe banner update karega
          else if (name.contains('RoomDisconnectedEvent')) {
            state = state.copyWith(isReconnecting: false); // new: Fix #1
          }

          else if (name.contains('ParticipantConnectedEvent')) {
            try {
              final userId = event.participant.identity as String;

              final alreadyInSpeakers  = state.members.any((m) => m.userId == userId);
              final alreadyInListeners = state.listeners.any((m) => m.userId == userId);

              if (!alreadyInSpeakers && !alreadyInListeners) {
                _repo.fetchMemberProfile(
                  userId,
                  groupId: _currentGroupId,
                ).then((profile) {
                  if (profile == null) return;

                  final stillAbsent =
                      !state.members.any((m) => m.userId == userId) &&
                      !state.listeners.any((m) => m.userId == userId);
                  if (!stillAbsent) return;

                  if (profile.role == 'speaker') {
                    state = state.copyWith(
                      members:      [...state.members, profile],
                      speakerCount: state.speakerCount + 1,
                    );
                  } else {
                    state = state.copyWith(
                      listeners:     [...state.listeners, profile],
                      listenerCount: state.listenerCount + 1,
                    );
                  }
                }).catchError((_) {});
              }
            } catch (_) {}
          }

          else if (name.contains('ParticipantDisconnectedEvent')) {
            final identity = event.participant.identity as String;

            final inSpeakers  = state.members.any((m) => m.userId == identity);
            final inListeners = state.listeners.any((m) => m.userId == identity);

            final leaving = inSpeakers
                ? state.members.firstWhere((m) => m.userId == identity)
                : inListeners
                    ? state.listeners.firstWhere((m) => m.userId == identity)
                    : VoiceMemberModel(
                        userId:  identity,
                        role:    'listener',
                        isMuted: false,
                      );

            final updatedSpeakers  =
                state.members.where((m) => m.userId != identity).toList();
            final updatedListeners =
                state.listeners.where((m) => m.userId != identity).toList();

            state = state.copyWith(
              myRole:        "speaker",
              justPromoted:  true,
              members:       updatedMembers,
              listeners:     updatedListeners,
              speakerCount:  state.speakerCount  + 1,
              listenerCount: meInListeners.isNotEmpty
                  ? (state.listenerCount - 1).clamp(0, 999)
                  : state.listenerCount,
            );
            _liveKit.enableMic();
          }
          break;
      }
    } catch (_) {}
  }

  void _onLiveKitReconnected() {
    if (_cleanedUp) return;

    _setupRoomListeners();

    if (_currentGroupId != null) {
      _repo.joinGroup(_currentGroupId!).catchError((_) {});
    }

    if (_currentGroupId != null) {
      _repo.fetchGroupMembers(_currentGroupId!).then((result) {
        if (_cleanedUp) return;
        if (result == null) {
          state = state.copyWith(isReconnecting: false);
          return;
        }
        state = state.copyWith(
          members:        result.speakers,
          listeners:      result.listeners,
          speakerCount:   result.speakerCount,
          listenerCount:  result.listenerCount,
          isReconnecting: false,
        );
      }).catchError((_) {
        if (_cleanedUp) return;
        state = state.copyWith(isReconnecting: false);
      });
    } else {
      state = state.copyWith(isReconnecting: false);
    }
  }

  void handleWebSocketPromotion(String? groupId) {
    if (_cleanedUp) return;
    if (groupId != null && groupId != _currentGroupId) return;

    final myId = UserSession.userId ?? "";
    if (myId.isEmpty) return;

    final meInListeners    = state.listeners.where((m) => m.userId == myId).toList();
    final updatedListeners = state.listeners.where((m) => m.userId != myId).toList();
    final alreadyInMembers = state.members.any((m) => m.userId == myId);

    final List<VoiceMemberModel> updatedMembers;

    if (alreadyInMembers) {
      updatedMembers = state.members.map((m) {
        if (m.userId != myId) return m;
        return VoiceMemberModel(
          userId:    m.userId,
          role:      "speaker",
          isMuted:   m.isMuted,
          name:      m.name,
          avatarUrl: m.avatarUrl,
          level:     m.level,
        );
      }).toList();
    } else {
      final promoted = meInListeners.isNotEmpty
          ? VoiceMemberModel(
              userId:    myId,
              role:      "speaker",
              isMuted:   false,
              name:      meInListeners.first.name,
              avatarUrl: meInListeners.first.avatarUrl,
              level:     meInListeners.first.level,
            )
          : VoiceMemberModel(
              userId:    myId,
              role:      "speaker",
              isMuted:   false,
              name:      UserSession.name,
              avatarUrl: UserSession.avatarUrl,
              level:     UserSession.level,
            );
      updatedMembers = [...state.members, promoted];
    }

    state = state.copyWith(
      myRole:        "speaker",
      justPromoted:  true,
      members:       updatedMembers,
      listeners:     updatedListeners,
      speakerCount:  state.speakerCount + 1,
      listenerCount: meInListeners.isNotEmpty
          ? (state.listenerCount - 1).clamp(0, 999)
          : state.listenerCount,
    );

    _liveKit.enableMic();
    debugPrint("🎙️ Promoted via WebSocket");
  }

  void _applyTrackMute(String userId, bool mute) {
    try {
      final room = _liveKit.room;
      if (room == null) return;

      for (final p in room.remoteParticipants.values) {
        if (p.identity != userId) continue;
        for (final pub in p.audioTrackPublications) {
          final track = pub.track;
          if (track != null) {
            mute ? track.disable() : track.enable();
          }
        }
      }
    } catch (_) {}
  }

  void _sendData(String message) {
    try {
      _liveKit.room?.localParticipant?.publishData(
        Uint8List.fromList(message.codeUnits),
        reliable: true,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    if (!_cleanedUp) {
      _cleanedUp              = true;
      _liveKit.onReconnected  = null; // new: Fix #6 — callback clear karo

      // modify: Fix #5 — expectedRoomId pass karo
      // Pehle: _liveKit.disconnect() — kisi bhi room ka connection cut ho sakta tha
      // Ab: Sirf is specific group ka disconnect hoga
      _liveKit.disconnect(
        expectedRoomId: _currentGroupId != null
            ? "vg-$_currentGroupId"
            : null,                            // new: Fix #5
      );

      if (_currentGroupId != null) {
        _repo.leaveGroupWithRetry(_currentGroupId!);
      }
    }
    _roomListener?.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────
//  PROVIDERS — unchanged
// ─────────────────────────────────────────────────────────

final voiceWorldRepositoryProvider =
    Provider<VoiceWorldRepository>((ref) {
  return VoiceWorldRepository.instance;
});

final voiceLiveKitProvider =
    Provider.autoDispose<LiveKitService>((ref) {
  final service = LiveKitService();
  ref.onDispose(() => service.disconnect());
  return service;
});

final voiceWorldProvider =
    StateNotifierProvider<VoiceWorldNotifier, VoiceWorldState>(
  (ref) => VoiceWorldNotifier(ref.read(voiceWorldRepositoryProvider)),
);

final voiceRoomProvider =
    StateNotifierProvider.autoDispose<VoiceRoomNotifier, VoiceRoomState>(
  (ref) => VoiceRoomNotifier(
    ref.read(voiceWorldRepositoryProvider),
    ref.read(voiceLiveKitProvider),
  ),
);
