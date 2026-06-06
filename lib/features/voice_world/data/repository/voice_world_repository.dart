import '../../../../core/network/api_client.dart';
import '../models/voice_group_model.dart';


// ─────────────────────────────────────────────────────
//  VOICE GROUP MEMBERS RESULT
//  fetchGroupMembers ka return type
// ─────────────────────────────────────────────────────

class VoiceGroupMembersResult {
  final List<VoiceMemberModel> speakers;
  final List<VoiceMemberModel> listeners;
  final int                    speakerCount;
  final int                    listenerCount;

  const VoiceGroupMembersResult({
    required this.speakers,
    required this.listeners,
    required this.speakerCount,
    required this.listenerCount,
  });
}
// ─────────────────────────────────────────────────────────
//  VOICE WORLD REPOSITORY
//  Sirf API calls — koi logic nahi, koi UI nahi
//  Har method ek API endpoint se baat karta hai
// ─────────────────────────────────────────────────────────

class VoiceWorldRepository {

  // ── Singleton — pure calls, state nahi ───────────────
  VoiceWorldRepository._internal();
  static final VoiceWorldRepository instance =
      VoiceWorldRepository._internal();

  // ─────────────────────────────────────────────────────
  //  GET WORLDS
  //  GET /voice/worlds
  // ─────────────────────────────────────────────────────

  Future<List<VoiceWorldModel>> getWorlds() async {
    try {

      final res = await ApiClient.get("/voice/worlds");

      final rawWorlds = res["worlds"] as List<dynamic>? ?? [];

      return rawWorlds
          .map((w) => VoiceWorldModel.fromJson(
                w as Map<String, dynamic>))
          .toList();

    } catch (e) {
      // Caller ko propagate karo — provider handle karega
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────
  //  JOIN GROUP
  //  POST /voice/join
  //  Returns: token + role
  // ─────────────────────────────────────────────────────

  Future<VoiceJoinResult> joinGroup(String groupId) async {
    try {

      final res = await ApiClient.post(
        "/voice/join",
        {"groupId": groupId},
      );

      return VoiceJoinResult.fromJson(res);

    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────
  //  LEAVE GROUP
  //  POST /voice/leave
  //  Fire and forget — crash pe bhi call karo
  // ─────────────────────────────────────────────────────

  Future<void> leaveGroup(String groupId) async {
    try {

      await ApiClient.post(
        "/voice/leave",
        {"groupId": groupId},
      );

    } catch (_) {
      // Leave silently fail ho sakta hai — log karo, throw mat karo
      // LiveKit webhook backup hai crash ke liye
    }
  }

  // ─────────────────────────────────────────────────────
  //  CHECK BAN STATUS
  //  GET /voice/ban-status
  //  Join se pehle call karo
  // ─────────────────────────────────────────────────────

  Future<VoiceBanStatus> getBanStatus() async {
    try {

      final res = await ApiClient.get("/voice/ban-status");
      return VoiceBanStatus.fromJson(res);

    } catch (e) {
      // Error pe safe default — banned nahi maano
      // Actual ban check backend join pe bhi hoga
      return VoiceBanStatus.notBanned();
    }
  }

  // new: Room mein join hone wale member ka profile fetch
  // voice_world_provider.dart mein ParticipantConnectedEvent pe call hoga
  Future<VoiceMemberModel?> fetchMemberProfile(String userId) async {
    try {
      // FIX: Timeout add kiya — slow network pe 5s baad null return karo
      // Pehle koi timeout nahi tha — indefinitely hang hota tha
      final res = await ApiClient.get("/voice/member/$userId")
          .timeout(const Duration(seconds: 5), onTimeout: () => {});

      if (res.isEmpty) return null;
      if (res["success"] != true) return null;

      return VoiceMemberModel(
        userId:    res["userId"]    as String,
        // FIX: Backend se real role lo — hardcoded speaker nahi
        role:      res["role"]      as String? ?? "speaker",
        isMuted:   false,
        name:      res["name"]      as String?,
        avatarUrl: res["avatarUrl"] as String?,
        level:     res["level"]     as int? ?? 1,
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────
  //  FETCH GROUP MEMBERS
  //  GET /voice/group/:groupId/members
  //  Reconnect ke baad fresh list — internet fix ke liye
  // ─────────────────────────────────────────────────────

  Future<VoiceGroupMembersResult?> fetchGroupMembers(String groupId) async {
    try {
      final res = await ApiClient.get("/voice/group/$groupId/members")
          .timeout(const Duration(seconds: 5), onTimeout: () => {});

      if (res.isEmpty) return null;
      if (res["success"] != true) return null;

      final rawSpeakers  = res["speakers"]  as List<dynamic>? ?? [];
      final rawListeners = res["listeners"] as List<dynamic>? ?? [];

      return VoiceGroupMembersResult(
        speakers: rawSpeakers.map((m) =>
            VoiceMemberModel.fromFlatJson(m as Map<String, dynamic>)
        ).toList(),
        listeners: rawListeners.map((m) =>
            VoiceMemberModel.fromFlatJson(m as Map<String, dynamic>)
        ).toList(),
        speakerCount:  res["speakerCount"]  as int? ?? 0,
        listenerCount: res["listenerCount"] as int? ?? 0,
      );

    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────
  //  LEAVE GROUP WITH RETRY
  //  Internet cut pe fail hone pe retry karo
  // ─────────────────────────────────────────────────────

  Future<void> leaveGroupWithRetry(String groupId) async {
    int attempts = 0;

    while (attempts < 3) {
      try {
        await ApiClient.post(
          "/voice/leave",
          {"groupId": groupId},
        ).timeout(const Duration(seconds: 5));
        return; // Success — bahar niklo
      } catch (_) {
        attempts++;
        if (attempts < 3) {
          // Retry se pehle thoda wait karo
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      }
    }
    // 3 baar fail — silently ignore (LiveKit webhook backup hai)
  }

  // ─────────────────────────────────────────────────────
  //  REPORT USER
  //  POST /voice/report
  // ─────────────────────────────────────────────────────

  Future<void> reportUser({
    required String reportedId,
    required String groupId,
    required String reason,
  }) async {
    try {

      await ApiClient.post(
        "/voice/report",
        {
          "reportedId": reportedId,
          "groupId":    groupId,
          "reason":     reason,
        },
      );

    } catch (e) {
      rethrow;
    }
  }
}
