import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/voice_world/data/models/voice_group_model.dart';
import '../features/voice_world/data/repository/voice_world_repository.dart';
import '../core/data/global_data_manager.dart';

import '../../../core/livekit/livekit_service.dart';
import '../../../core/session/user_session.dart';

// ─────────────────────────────────────────────────────────
//  VOICE CHAT MESSAGE MODEL
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
//  ENUMS + STATES
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
//  VOICE WORLD NOTIFIER
// ─────────────────────────────────────────────────────────

class VoiceWorldNotifier extends StateNotifier<VoiceWorldState> {

  final VoiceWorldRepository _repo;

  VoiceWorldNotifier(this._repo) : super(const VoiceWorldState());

  Future<void> fetchWorlds() async {
    state = state.copyWith(status: VoiceWorldStatus.loading);
    try {
      final worlds = await _repo.getWorlds();
      state = state.copyWith(status: VoiceWorldStatus.loaded, worlds: worlds);

      // ✅ NAYA: SQLite mein save karo
      await GlobalDataManager.instance.setRooms(
        worlds.map((w) => w.toJson()).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        status:       VoiceWorldStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ✅ NAYA: Cache se load karo
  Future<void> loadFromCache() async {
    final cached = GlobalDataManager.instance.rooms;
    if (cached == null || cached.isEmpty) return;

    try {
      final worlds = cached
          .map((r) => VoiceWorldModel.fromJson(r as Map<String, dynamic>))
          .toList();

      if (worlds.isNotEmpty) {
        state = state.copyWith(
          status: VoiceWorldStatus.loaded,
          worlds: worlds,
        );
      }
    } catch (e) {
      debugPrint("⚠️ VoiceWorld loadFromCache failed: $e");
    }
  }

  void onSearchChanged(String query) =>
      state = state.copyWith(searchQuery: query);

  void clearSearch() => state = state.copyWith(searchQuery: "");

  Future<void> refresh() => fetchWorlds();
}

// ─────────────────────────────────────────────────────────
//  VOICE ROOM STATE
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

  VoiceRoomNotifier(this._repo, this._liveKit)
      : super(const VoiceRoomState()) {
    _liveKit.onReconnected = _onLiveKitReconnected;
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

      // note: group.members yahan WORLDS SCREEN ka purana snapshot hai
      // Isiliye sirf OPTIMISTIC (turant) UI feedback ke liye use karo
      // Asli truth neeche _refreshMembersFromBackend() se aayegi
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

      // new: Fix #17 — Stale snapshot ko backend ki authoritative
      // truth se overwrite karo. Worlds-list kabhi bhi purana ho sakta hai
      // (naye log join hue, purane left hue) — ye fetch turant sahi karta hai
      // Profile (name/avatarUrl) bhi backend se 100% correct aayega,
      // chahe UserSession abhi load na hua ho
      _refreshMembersFromBackend(group.id);

    } catch (e) {
      _liveKit.disconnect(
        expectedRoomId: "vg-${group.id}",
      ).catchError((_) {});

      state = state.copyWith(
        joinStatus:    VoiceJoinStatus.error,
        errorMessage:  e.toString(),
        members:       [],
        listeners:     [],
        speakerCount:  0,
        listenerCount: 0,
      );
    }
  }

  // ── JOIN WITH TOKEN ───────────────────────────────────
  // NOTE: Prefetch hatne ke baad ye method abhi unreachable hai
  // (voice_world_screen.dart hamesha preloadedResult: null bhejta hai)
  // Future-proofing ke liye fix consistent rakha hai
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

      final myId        = UserSession.userId ?? "";
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

      // new: Fix #17 — same backend refresh
      _refreshMembersFromBackend(group.id);

    } catch (e) {
      _liveKit.disconnect(
        expectedRoomId: "vg-${group.id}",
      ).catchError((_) {});

      state = state.copyWith(
        joinStatus:    VoiceJoinStatus.error,
        errorMessage:  e.toString(),
        members:       [],
        listeners:     [],
        speakerCount:  0,
        listenerCount: 0,
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

    _liveKit.onReconnected = null;
    _liveKit.disconnect(
      expectedRoomId: "vg-$groupId",
    ).catchError((_) {});

    _repo.leaveGroupWithRetry(groupId);

    _roomListener?.dispose();
    _roomListener   = null;
    _currentGroupId = null;

    state = const VoiceRoomState();
  }

  // ── MIC CONTROLS ─────────────────────────────────────
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
  //  SETUP ROOM LISTENERS
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

          else if (name.contains('RoomDisconnectedEvent')) {
            state = state.copyWith(isReconnecting: false);
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
            try {
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
                members:       updatedSpeakers,
                listeners:     updatedListeners,
                speakerCount:  (leaving.role == 'speaker' && inSpeakers)
                    ? (state.speakerCount  - 1).clamp(0, 999)
                    : state.speakerCount,
                listenerCount: (leaving.role == 'listener' && inListeners)
                    ? (state.listenerCount - 1).clamp(0, 999)
                    : state.listenerCount,
              );
            } catch (_) {}
          }

          else if (name.contains('DataReceivedEvent')) {
            _handleDataMessage(event);
          }
        });
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────
  //  BACKEND SYNC HELPER — Fix #17 (NEW)
  //
  //  Har join/rejoin ke baad ye call hota hai. Worlds-list snapshot
  //  kabhi bhi stale ho sakta hai — ye backend se ground-truth leke
  //  state ko overwrite karta hai. Fetch fail ho jaaye (network down)
  //  toh optimistic placeholder hi rehne do — silently ignore karo,
  //  next reconnect cycle ya ParticipantConnectedEvent fix kar dega.
  // ─────────────────────────────────────────────────────

  Future<void> _refreshMembersFromBackend(String groupId) async {
    try {
      final result = await _repo.fetchGroupMembers(groupId);

      // Guard: user already kahin aur switch ho gaya ya leave kar diya
      if (_cleanedUp || _currentGroupId != groupId) return;
      if (result == null) return;

      state = state.copyWith(
        members:       result.speakers,
        listeners:     result.listeners,
        speakerCount:  result.speakerCount,
        listenerCount: result.listenerCount,
      );
    } catch (_) {
      // Optimistic placeholder hi rehne do
    }
  }

  // ─────────────────────────────────────────────────────
  //  LIVEKIT RECONNECTED CALLBACK — Fix #18: Race condition fix
  //
  //  Pehle: _repo.joinGroup() aur _repo.fetchGroupMembers() ek saath
  //         fire hote the — agar fetch pehle resolve hota,
  //         "main" hi list mein missing rehta tha
  //  Ab: pehle DB membership ensure karo (await), TAB fresh list lo
  // ─────────────────────────────────────────────────────

  Future<void> _onLiveKitReconnected() async {
    if (_cleanedUp) return;

    _setupRoomListeners();

    if (_currentGroupId == null) {
      state = state.copyWith(isReconnecting: false);
      return;
    }

    final groupId = _currentGroupId!;

    try {
      await _repo.joinGroup(groupId);
    } catch (_) {
      // Already member (alreadyJoined) ya transient fail —
      // dono cases mein aage badho, fetchGroupMembers self-correct karega
    }

    if (_cleanedUp || _currentGroupId != groupId) return;

    try {
      final result = await _repo.fetchGroupMembers(groupId);

      if (_cleanedUp || _currentGroupId != groupId) return;

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
    } catch (_) {
      if (_cleanedUp) return;
      state = state.copyWith(isReconnecting: false);
    }
  }

  // ─────────────────────────────────────────────────────
  //  WEBSOCKET PROMOTION HANDLER
  // ─────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────
  //  DATA MESSAGE HANDLER
  // ─────────────────────────────────────────────────────

  void _handleDataMessage(dynamic event) {
    try {
      final raw   = String.fromCharCodes(event.data);
      final colon = raw.indexOf(":");
      if (colon < 0) return;

      final type   = raw.substring(0, colon);
      final target = raw.substring(colon + 1);
      final sender = event.participant?.identity ?? "";
      final myId   = UserSession.userId ?? "";

      switch (type) {
        case "BI_MUTE":
          if (target == myId) {
            _liveKit.disableMic();
            state = state.copyWith(isMicOn: false);
          }
          _applyTrackMute(sender, true);
          break;

        case "BI_UNMUTE":
          if (target == myId && state.isSpeaker) {
            _liveKit.enableMic();
            state = state.copyWith(isMicOn: true);
          }
          _applyTrackMute(sender, false);
          break;

        case "ROOM_CHAT":
          try {
            final data = jsonDecode(target) as Map<String, dynamic>;

            final senderId = sender;
            if (senderId == myId) break;

            final chatMsg = VoiceChatMessage(
              userId:    senderId,
              name:      data["name"]      as String? ?? "User",
              avatarUrl: data["avatarUrl"] as String?,
              message:   data["message"]   as String? ?? "",
              time:      DateTime.tryParse(
                           data["time"] as String? ?? "",
                         ) ?? DateTime.now(),
              isMe:      false,
            );

            final msgs = [...state.chatMessages, chatMsg];
            if (msgs.length > 100) msgs.removeAt(0);
            state = state.copyWith(chatMessages: msgs);
          } catch (_) {}
          break;

        case "PROMOTED_TO_SPEAKER":
          if (target == myId) {
            final meInListeners = state.listeners
                .where((m) => m.userId == myId)
                .toList();

            final updatedListeners = state.listeners
                .where((m) => m.userId != myId)
                .toList();

            final alreadyInMembers =
                state.members.any((m) => m.userId == myId);

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

  // ─────────────────────────────────────────────────────
  //  TRACK MUTE
  // ─────────────────────────────────────────────────────

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
      _cleanedUp             = true;
      _liveKit.onReconnected = null;

      _liveKit.disconnect(
        expectedRoomId: _currentGroupId != null
            ? "vg-$_currentGroupId"
            : null,
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
//  PROVIDERS
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
