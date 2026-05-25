// ─────────────────────────────────────────────────────────
//  VOICE GROUP MODEL
//  Pure data class — no logic, no UI
//  Sirf JSON → Dart object conversion
// ─────────────────────────────────────────────────────────

class VoiceMemberModel {
  final String  userId;
  final String  role;       // "speaker" | "listener"
  final bool    isMuted;
  final String? name;
  final String? avatarUrl;
  final int     level;

  const VoiceMemberModel({
    required this.userId,
    required this.role,
    required this.isMuted,
    this.name,
    this.avatarUrl,
    this.level = 1,
  });

  bool get isSpeaker => role == "speaker";

  factory VoiceMemberModel.fromJson(Map<String, dynamic> json) {
    final user    = json["user"] as Map<String, dynamic>?;
    final profile = user?["profile"] as Map<String, dynamic>?;

    return VoiceMemberModel(
      userId:    json["userId"] as String,
      role:      json["role"]   as String? ?? "listener",
      isMuted:   json["isMuted"] as bool?  ?? false,
      name:      profile?["name"]      as String?,
      avatarUrl: profile?["avatarUrl"] as String?,
      level:     user?["level"]        as int? ?? 1,
    );
  }

  // Local mute copy — backend call nahi hota
  VoiceMemberModel copyWithMuted(bool muted) {
    return VoiceMemberModel(
      userId:    userId,
      role:      role,
      isMuted:   muted,
      name:      name,
      avatarUrl: avatarUrl,
      level:     level,
    );
  }
}

// ─────────────────────────────────────────────────────────

class VoiceGroupModel {
  final String              id;
  final String              shortId;
  final String              name;
  final String              emoji;
  final int                 speakerCount;
  final int                 listenerCount;
  final int                 maxSpeakers;
  final List<VoiceMemberModel> members;

  const VoiceGroupModel({
    required this.id,
    required this.shortId,
    required this.name,
    required this.emoji,
    required this.speakerCount,
    required this.listenerCount,
    required this.maxSpeakers,
    required this.members,
  });

  // ── Computed helpers — UI mein directly use karo ──────

  bool get isSpeakerFull => speakerCount >= maxSpeakers;

  // Listeners unlimited hain — kabhi full nahi
  bool get canJoinAsSpeaker => !isSpeakerFull;

  int  get totalMembers => speakerCount + listenerCount;

  List<VoiceMemberModel> get speakers =>
      members.where((m) => m.isSpeaker).toList();

  List<VoiceMemberModel> get listeners =>
      members.where((m) => !m.isSpeaker).toList();

  factory VoiceGroupModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json["members"] as List<dynamic>? ?? [];

    return VoiceGroupModel(
      id:            json["id"]            as String,
      shortId:       json["shortId"]       as String,
      name:          json["name"]          as String,
      emoji:         json["emoji"]         as String? ?? "🎙️",
      speakerCount:  json["speakerCount"]  as int?    ?? 0,
      listenerCount: json["listenerCount"] as int?    ?? 0,
      maxSpeakers:   json["maxSpeakers"]   as int?    ?? 16,
      members: rawMembers
          .map((m) => VoiceMemberModel.fromJson(
                m as Map<String, dynamic>))
          .toList(),
    );
  }

  // Count update ke liye — fresh fetch se pehle optimistic UI
  VoiceGroupModel copyWith({
    int?                     speakerCount,
    int?                     listenerCount,
    List<VoiceMemberModel>?  members,
  }) {
    return VoiceGroupModel(
      id:            id,
      shortId:       shortId,
      name:          name,
      emoji:         emoji,
      speakerCount:  speakerCount  ?? this.speakerCount,
      listenerCount: listenerCount ?? this.listenerCount,
      maxSpeakers:   maxSpeakers,
      members:       members       ?? this.members,
    );
  }
}

// ─────────────────────────────────────────────────────────

class VoiceWorldModel {
  final String                id;
  final String                name;
  final String                emoji;
  final List<VoiceGroupModel> groups;

  const VoiceWorldModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.groups,
  });

  factory VoiceWorldModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json["groups"] as List<dynamic>? ?? [];

    return VoiceWorldModel(
      id:     json["id"]    as String,
      name:   json["name"]  as String,
      emoji:  json["emoji"] as String? ?? "🌍",
      groups: rawGroups
          .map((g) => VoiceGroupModel.fromJson(
                g as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  JOIN RESULT MODEL
//  /voice/join ke response ko hold karta hai
// ─────────────────────────────────────────────────────────

class VoiceJoinResult {
  final String token;
  final String role;    // "speaker" | "listener"

  const VoiceJoinResult({
    required this.token,
    required this.role,
  });

  bool get isSpeaker => role == "speaker";

  factory VoiceJoinResult.fromJson(Map<String, dynamic> json) {
    return VoiceJoinResult(
      token: json["token"] as String,
      role:  json["role"]  as String? ?? "listener",
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BAN STATUS MODEL
//  /voice/ban-status ke response
// ─────────────────────────────────────────────────────────

class VoiceBanStatus {
  final bool      banned;
  final int?      banLevel;
  final DateTime? expiresAt;
  final bool      permanent;

  const VoiceBanStatus({
    required this.banned,
    this.banLevel,
    this.expiresAt,
    this.permanent = false,
  });

  // Countdown string — UI mein dikhane ke liye
  String get remainingText {
    if (!banned)    return "";
    if (permanent)  return "Permanent";
    if (expiresAt == null) return "";

    final diff = expiresAt!.difference(DateTime.now());
    if (diff.inHours >= 1) return "${diff.inHours}h remaining";
    return "${diff.inMinutes}m remaining";
  }

  factory VoiceBanStatus.fromJson(Map<String, dynamic> json) {
    return VoiceBanStatus(
      banned:    json["banned"]    as bool? ?? false,
      banLevel:  json["banLevel"]  as int?,
      permanent: json["permanent"] as bool? ?? false,
      expiresAt: json["expiresAt"] != null
          ? DateTime.tryParse(json["expiresAt"] as String)
          : null,
    );
  }

  factory VoiceBanStatus.notBanned() {
    return const VoiceBanStatus(banned: false);
  }
}
