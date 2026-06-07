import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/voice_world/data/models/voice_group_model.dart';
import '../features/voice_world/data/repository/voice_world_repository.dart';

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
//  VOICE WORLD STATE
//  World screen ka state — fetch, search
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

  // ── ShortId se group filter ───────────────────────────
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
      state = state.copyWith(
        status: VoiceWorldStatus.loaded,
        worlds: worlds,
      );
    } catch (e) {
      state = state.copyWith(
        status:       VoiceWorldStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void onSearchChanged(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: "");
  }

  Future<void> refresh() => fetchWorlds();
}

// ─────────────────────────────────────────────────────────
//  VOICE ROOM STATE
//  Room ke andar ka poora state
// ─────────────────────────────────────────────────────────

class VoiceRoomState {
  final VoiceJoinStatus        joinStatus;
  final String?                errorMessage;
  final String?                myRole;
  final bool                   isMicOn;
  final List<VoiceMemberModel> members;

  // Local mute — sirf is device pe, doosre ko pata nahi
  final Map<String, bool>      localMutedUsers;

  // Bi-directional mute — dono taraf band
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

  bool isLocalMuted(String userId) =>
      localMutedUsers[userId] == true;

  bool isBiMuted(String userId) =>
      biMutedUsers.contains(userId);

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
//  Room lifecycle — join, leave, mute, reconnect
// ─────────────────────────────────────────────────────────

class VoiceRoomNotifier extends StateNotifier<VoiceRoomState> {

  final VoiceWorldRepository _repo;
  final LiveKitService       _liveKit;

  dynamic  _roomListener;
  String?  _currentGroupId; // Abhi kis room mein hai
  bool     _cleanedUp = false; // Double cleanup prevent karo

  VoiceRoomNotifier(this._repo, this._liveKit)
      : super(const VoiceRoomState());

  // ── JOIN ─────────────────────────────────────────────
  Future<void> joinGroup(VoiceGroupModel group) async {
    if (state.joinStatus == VoiceJoinStatus.joining) return;

    state = state.copyWith(joinStatus: VoiceJoinStatus.joining);

    try {
      // fix: Ban check remove kiya — backend joinGroup andar hi check karta hai
      // Agar banned hai toh backend PERMANENTLY_BANNED error throw karega
      // jo catch block handle kar lega — 1 API call ki jagah ab 1 hi hogi
      // 2. Join API — backend se token + role milega
      final result = await _repo.joinGroup(group.id);

      // 3. LiveKit connect
      _liveKit.reset();
      await _liveKit.connectWithToken(
        token:  result.token,
        roomId: "vg-${group.id}",
        role:   result.role,
      );

      // 4. Current group track karo (cleanup ke liye)
      _currentGroupId = group.id;

      // 5. Room listeners
      _setupRoomListeners();

      // fix: Pehle placeholder se turant seat fill karo
      final myId = UserSession.userId ?? "";

      final placeholder = VoiceMemberModel(
        userId:    myId,
        role:      result.role,
        isMuted:   false,
        name:      UserSession.name,
        avatarUrl: UserSession.avatarUrl,
        level:     UserSession.level,
      );

      // FIX: Speakers aur listeners alag karo join pe
      final existingSpeakers  = group.members.where((m) => m.isSpeaker).toList();
      final existingListeners = group.members.where((m) => !m.isSpeaker).toList();

      final alreadyIn = group.members.any((m) => m.userId == myId);

      // Placeholder sahi list mein daalo role ke hisaab se
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
      state = state.copyWith(
        joinStatus:   VoiceJoinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── LEAVE ────────────────────────────────────────────
  Future<void> leaveGroup(String groupId) async {
    if (_cleanedUp) return;
    _cleanedUp = true;

    // FIX: Turant UI clear karo — user ko instant feedback
    state = state.copyWith(
      joinStatus: VoiceJoinStatus.leaving,
      members:    [],
      listeners:  [],
    );

    await _liveKit.disconnect();

    // FIX: Retry logic — internet cut pe bhi leave backend pe ho
    await _repo.leaveGroupWithRetry(groupId);

    _roomListener?.dispose();
    _roomListener = null;
    _currentGroupId = null;

    state = const VoiceRoomState();
  }
  // ── SELF MIC TOGGLE ──────────────────────────────────
  Future<void> toggleMic() async {
    if (!state.isSpeaker) return;
    final newMicState = !state.isMicOn;
    await _liveKit.toggleMic();
    state = state.copyWith(isMicOn: newMicState);
  }

  // ── LOCAL MUTE — sirf apne liye, doosre ko pata nahi ─
  void toggleLocalMute(String userId) {
    final updated = Map<String, bool>.from(state.localMutedUsers);
    final current = updated[userId] == true;
    updated[userId] = !current;
    _applyTrackMute(userId, !current);
    state = state.copyWith(localMutedUsers: updated);
  }

  // ── BI-DIRECTIONAL MUTE — dono taraf ─────────────────
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

  // ── REPORT ───────────────────────────────────────────
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

  // new: Live room chat message bhejo via LiveKit Data Channel
  // Backend involve nahi — zero server load
  void sendChatMessage(String message) {
    if (message.trim().isEmpty) return;

    final myId = UserSession.userId ?? "";

    // Apni info members list se lo
    final me = state.members.firstWhere(
      (m) => m.userId == myId,
      orElse: () => VoiceMemberModel(
        userId:  myId,
        role:    'listener',
        isMuted: false,
      ),
    );

    // new: Local mein turant add karo — apna message dikhao
    final chatMsg = VoiceChatMessage(
      userId:    myId,
      name:      me.name ?? "User",
      avatarUrl: me.avatarUrl,
      message:   message.trim(),
      time:      DateTime.now(),
      isMe:      true,
    );

    // new: Max 100 messages rakho — memory leak prevent
    final updated = [...state.chatMessages, chatMsg];
    if (updated.length > 100) updated.removeAt(0);

    state = state.copyWith(chatMessages: updated);

    // new: Sab room members ko LiveKit Data Channel se bhejo
    // Backend ka koi kaam nahi — LiveKit directly deliver karta hai
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

        // Active speakers — speaking glow animation
        if (name.contains('ActiveSpeakersChangedEvent')) {
          try {
            final speakers = (event.speakers as List)
                .map<String>((s) => s.identity as String)
                .toSet();
            state = state.copyWith(activeSpeakers: speakers);
          } catch (_) {}
        }

        // Reconnecting
        else if (name.contains('RoomReconnectingEvent')) {
          state = state.copyWith(isReconnecting: true);
        }

        // Reconnected — fresh member list fetch karo
        else if (name.contains('RoomReconnectedEvent')) {
          state = state.copyWith(isReconnecting: false);

          // FIX: Internet cut ke dauran jo join/leave hue unka record nahi tha
          // Fresh fetch se seat grid + listener list dono ek saath update hongi
          if (_currentGroupId != null) {
            _repo.fetchGroupMembers(_currentGroupId!).then((result) {
              if (result == null) return;
              state = state.copyWith(
                members:       result.speakers,
                listeners:     result.listeners,
                speakerCount:  result.speakerCount,
                listenerCount: result.listenerCount,
              );
            }).catchError((_) {});
          }
        }

        // Participant disconnected
        else if (name.contains('ParticipantConnectedEvent')) {
                  try {
                    final userId = event.participant.identity as String;

                    // FIX: Dono lists mein check karo
                    final alreadyInSpeakers  = state.members.any((m) => m.userId == userId);
                    final alreadyInListeners = state.listeners.any((m) => m.userId == userId);

                    if (!alreadyInSpeakers && !alreadyInListeners) {
                      // FIX: groupId pass karo — backend real role dega
                      _repo.fetchMemberProfile(
                        userId,
                        groupId: _currentGroupId,
                      ).then((profile) {
                        if (profile == null) return;

                        // Abhi bhi absent hai? Tab hi add karo
                        final stillAbsent =
                            !state.members.any((m) => m.userId == userId) &&
                            !state.listeners.any((m) => m.userId == userId);
                        if (!stillAbsent) return;

                        if (profile.role == 'speaker') {
                          // Speaker — seat grid mein
                          state = state.copyWith(
                            members:      [...state.members, profile],
                            speakerCount: state.speakerCount + 1,
                          );
                        } else {
                          // Listener — listener list mein
                          state = state.copyWith(
                            listeners:     [...state.listeners, profile],
                            listenerCount: state.listenerCount + 1,
                          );
                        }
                      }).catchError((_) {});
                    }
                    
        // Participant disconnected
        // Participant disconnected
        else if (name.contains('ParticipantDisconnectedEvent')) {
          final identity = event.participant.identity as String;

          // FIX: Dono lists mein check karo
          final inSpeakers  = state.members.any((m) => m.userId == identity);
          final inListeners = state.listeners.any((m) => m.userId == identity);

          final leaving = inSpeakers
              ? state.members.firstWhere((m) => m.userId == identity)
              : inListeners
                  ? state.listeners.firstWhere((m) => m.userId == identity)
                  : VoiceMemberModel(userId: identity, role: 'listener', isMuted: false);

          // Dono lists se remove karo
          final updatedSpeakers  = state.members.where((m) => m.userId != identity).toList();
          final updatedListeners = state.listeners.where((m) => m.userId != identity).toList();

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
        }
        // Data received
        else if (name.contains('DataReceivedEvent')) {
          _handleDataMessage(event);
        }
      });
  } catch (_) {}
  }

  void _handleDataMessage(dynamic event) {
    try {
      final raw   = String.fromCharCodes(event.data);
      // Format: "TYPE:targetUserId"
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

          // new: Live room chat message receive karo
        case "ROOM_CHAT":
          try {
            final data     = jsonDecode(target) as Map<String, dynamic>;
            final myId     = UserSession.userId ?? "";
            final senderId = data["userId"] as String? ?? "";

            // new: Apna hi message dobara add mat karo
            if (senderId == myId) break;

            final chatMsg = VoiceChatMessage(
              userId:    senderId,
              name:      data["name"]      as String? ?? "User",
              avatarUrl: data["avatarUrl"] as String?,
              message:   data["message"]   as String?  ?? "",
              time:      DateTime.tryParse(
                           data["time"] as String? ?? ""
                         ) ?? DateTime.now(),
              isMe:      false,
            );

            // new: Max 100 messages
            final msgs = [...state.chatMessages, chatMsg];
            if (msgs.length > 100) msgs.removeAt(0);

            state = state.copyWith(chatMessages: msgs);
          } catch (_) {}
          break;

        case "PROMOTED_TO_SPEAKER":
          if (target == myId) {
            final updatedMembers = state.members.map((m) {
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
            state = state.copyWith(
              myRole:       "speaker",
              justPromoted: true,
              members:      updatedMembers,
            );
            _liveKit.enableMic();
          }
          break;
      }
    } catch (_) {}
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
      _cleanedUp = true;
      _liveKit.disconnect();
      if (_currentGroupId != null) {
        _repo.leaveGroup(_currentGroupId!);
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
    Provider<LiveKitService>((ref) {
  final service = LiveKitService();
  ref.onDispose(() => service.disconnect());
  return service;
});

// World screen — persist karo (tab switch pe reload nahi)
final voiceWorldProvider =
    StateNotifierProvider<VoiceWorldNotifier, VoiceWorldState>(
  (ref) => VoiceWorldNotifier(ref.read(voiceWorldRepositoryProvider)),
);

// Room — autoDispose: screen close pe sab cleanup
final voiceRoomProvider =
    StateNotifierProvider.autoDispose<VoiceRoomNotifier, VoiceRoomState>(
  (ref) => VoiceRoomNotifier(
    ref.read(voiceWorldRepositoryProvider),
    ref.read(voiceLiveKitProvider),
  ),
);
