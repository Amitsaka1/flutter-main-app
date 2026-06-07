// ─────────────────────────────────────────────────────────
//  VOICE WORLD CONSTANTS
//  Path: lib/features/voice_world/core/voice_constants.dart
//  Saare magic numbers yahan — ek jagah se control karo
// ─────────────────────────────────────────────────────────

class VoiceConstants {

  VoiceConstants._(); // Instantiate mat karo

  // ── Seats ────────────────────────────────────────────
  /// Ek room mein max speaker seats
  static const int maxSpeakers = 16;

  // ── Chat ─────────────────────────────────────────────
  /// Ek message mein max characters
  static const int maxMessageLength = 200;

  /// Memory mein max chat messages rakho
  static const int maxChatMessages = 100;

  // ── Listener Bar ─────────────────────────────────────
  /// Bar pe dikhne wale mini avatars
  static const int listenerAvatarPreviewCount = 5;

  // ── Network ──────────────────────────────────────────
  /// Member profile fetch timeout
  static const Duration memberProfileTimeout = Duration(seconds: 5);

  /// Leave group retry attempts
  static const int leaveRetryAttempts = 3;

  /// Leave group retry base delay (seconds)
  static const int leaveRetryBaseDelay = 2;

  // ── Redis TTL ────────────────────────────────────────
  /// Member profile cache — 5 minutes
  static const int memberProfileCacheTtl = 300;

  /// Group members cache — 3 seconds (near real-time)
  static const int groupMembersCacheTtl = 3;

  /// Leave lock TTL — 10 seconds
  static const int leaveLockTtl = 10;

  // ── Animation ────────────────────────────────────────
  /// Mic pulse animation duration
  static const Duration micPulseDuration = Duration(milliseconds: 900);

  /// Speaking glow animation duration
  static const Duration glowDuration = Duration(milliseconds: 700);

  /// Listening indicator animation duration
  static const Duration listenDuration = Duration(milliseconds: 1200);

  // ── UI ───────────────────────────────────────────────
  /// Chat scroll delay after send
  static const Duration chatScrollDelay = Duration(milliseconds: 100);

  /// Chat scroll animation duration
  static const Duration chatScrollDuration = Duration(milliseconds: 200);
}
