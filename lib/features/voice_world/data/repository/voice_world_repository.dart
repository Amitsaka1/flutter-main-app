import '../../../../core/network/api_client.dart';
import '../models/voice_group_model.dart';

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
      final res = await ApiClient.get("/voice/member/$userId");

      if (res["success"] != true) return null;

      return VoiceMemberModel(
        userId:    res["userId"]    as String,
        role:      "speaker",
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
