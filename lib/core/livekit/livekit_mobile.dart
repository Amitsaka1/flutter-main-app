import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:app_project/core/config/environment.dart';

class LiveKitService {

  Room? _room;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentRole;

  bool _isConnecting = false;
  bool _isDisposed   = false;

  Timer?  _reconnectTimer;
  int     _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  EventsListener<RoomEvent>? _listener;

  // ── Public getters ────────────────────────────
  Room? get room        => _room;
  bool  get isConnected =>
      _room?.connectionState == ConnectionState.connected;

  // ─────────────────────────────────────────────
  //  CONNECT — khud token fetch karta hai
  //  1:1 calls ke liye (existing — unchanged)
  // ─────────────────────────────────────────────
  Future<void> connect({
    required String userId,
    required String roomId,
    required String role,
  }) async {

    if (_isConnecting) return;
    if (_isDisposed)   return;

    _isConnecting  = true;
    _currentRoomId = roomId;
    _currentUserId = userId;
    _currentRole   = role;

    try {

      if (_room != null &&
          _room!.connectionState == ConnectionState.connected &&
          _room!.name == roomId) {
        _isConnecting = false;
        return;
      }

      await _cleanupRoom();

      final token = await _fetchToken(
        userId: userId,
        roomId: roomId,
        role:   role,
      );

      if (_isDisposed) return;

      await _connectToRoom(token: token, role: role);

    } catch (e) {
      debugPrint("❌ LiveKit connect error: $e");
      _scheduleReconnect();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  // ─────────────────────────────────────────────
  //  CONNECT WITH TOKEN — bahar se token aata hai
  //  🔥 NEW — Voice World ke liye
  //  /voice/join se already token aa chuka hota hai
  //  Alag token fetch nahi hoti — cost save + fast
  // ─────────────────────────────────────────────
  Future<void> connectWithToken({
    required String token,
    required String roomId,
    required String role,
  }) async {

    if (_isConnecting) return;
    if (_isDisposed)   return;

    _isConnecting  = true;
    _currentRoomId = roomId;
    _currentRole   = role;
    // userId token mein encoded hai — separately store nahi
    _currentUserId = null;

    try {

      // Already same room mein connected?
      if (_room != null &&
          _room!.connectionState == ConnectionState.connected &&
          _room!.name == roomId) {
        _isConnecting = false;
        return;
      }

      await _cleanupRoom();

      if (_isDisposed) return;

      await _connectToRoom(token: token, role: role);

    } catch (e) {
      debugPrint("❌ LiveKit connectWithToken error: $e");
      _scheduleReconnect();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  // ─────────────────────────────────────────────
  //  SHARED CONNECT LOGIC
  //  Dono connect methods yahan aate hain
  // ─────────────────────────────────────────────
  Future<void> _connectToRoom({
    required String token,
    required String role,
  }) async {

    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast:       true,
        defaultAudioCaptureOptions: AudioCaptureOptions(
          echoCancellation:  true,
          noiseSuppression:  true,
          autoGainControl:   true,
        ),
        defaultAudioOutputOptions: AudioOutputOptions(
          speakerOn: true,
        ),
      ),
    );

    await room.connect(
      Environment.livekitUrl,
      token,
      connectOptions: const ConnectOptions(
        autoSubscribe: true,
      ),
    );

    if (_isDisposed) {
      await room.disconnect();
      return;
    }

    _room = room;
    _reconnectAttempts = 0;

    _setupListeners(role: role);

    // Mic — role ke hisab se
    if (role == "speaker") {
      await room.localParticipant?.setMicrophoneEnabled(true);
    } else {
      await room.localParticipant?.setMicrophoneEnabled(false);
    }

    debugPrint("✅ LiveKit connected: ${_currentRoomId} ($role)");
  }

  // ─────────────────────────────────────────────
  //  SETUP LISTENERS
  // ─────────────────────────────────────────────
  void _setupListeners({ required String role }) {

    _listener?.dispose();
    _listener = _room!.createListener();

    _listener!
      ..on<TrackSubscribedEvent>((event) {
        final track = event.track;
        if (track is RemoteAudioTrack) {
          track.start();
          debugPrint("🔊 Remote audio started");
        }
      })

      ..on<RoomReconnectingEvent>((_) {
        debugPrint("⚠️ LiveKit reconnecting...");
      })

      ..on<RoomReconnectedEvent>((_) async {
        debugPrint("✅ LiveKit reconnected");
        _reconnectAttempts = 0;

        // Mic restore
        if (role == "speaker") {
          await _room?.localParticipant
              ?.setMicrophoneEnabled(true);
        }
      })

      ..on<RoomDisconnectedEvent>((event) {
        debugPrint(
          "❌ LiveKit disconnected: ${event.reason}",
        );

        if (event.reason !=
                DisconnectReason.clientInitiated &&
            !_isDisposed) {
          _scheduleReconnect();
        }
      });
  }

  // ─────────────────────────────────────────────
  //  FETCH TOKEN — sirf 1:1 calls ke liye
  // ─────────────────────────────────────────────
  Future<String> _fetchToken({
    required String userId,
    required String roomId,
    required String role,
  }) async {

    final res = await http.post(
      Uri.parse("${Environment.baseUrl}/livekit/token"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "roomId": roomId,
        "role":   role,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(res.body);

    if (data["success"] != true) {
      throw Exception(
          "LiveKit token failed: ${data["message"]}");
    }

    return data["token"];
  }

  // ─────────────────────────────────────────────
  //  RECONNECT — exponential backoff
  // ─────────────────────────────────────────────
  void _scheduleReconnect() {

    if (_isDisposed) return;
    if (_currentRoomId == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint("❌ Max reconnect attempts reached");
      return;
    }

    _reconnectTimer?.cancel();

    // 2s, 4s, 8s, 16s ... max 30s
    final delay = Duration(
      seconds: (_reconnectAttempts < 4)
          ? (2 * (_reconnectAttempts + 1))
          : 30,
    );

    _reconnectAttempts++;

    debugPrint(
      "🔄 Reconnect #$_reconnectAttempts in ${delay.inSeconds}s",
    );

    _reconnectTimer = Timer(delay, () async {
      if (_isDisposed) return;
      try {
        // Token already hai toh reconnect direct
        // Nahi hai toh original connect call
        if (_currentUserId != null) {
          await connect(
            userId: _currentUserId!,
            roomId: _currentRoomId!,
            role:   _currentRole!,
          );
        }
        // Voice World reconnect — provider handle karega
        // (room screen ka voiceRoomProvider autoDispose hai)
      } catch (_) {}
    });
  }

  // ─────────────────────────────────────────────
  //  MIC CONTROLS
  // ─────────────────────────────────────────────
  Future<void> enableMic() async {
    await _room?.localParticipant
        ?.setMicrophoneEnabled(true);
  }

  Future<void> disableMic() async {
    await _room?.localParticipant
        ?.setMicrophoneEnabled(false);
  }

  Future<void> toggleMic() async {
    final isEnabled =
        _room?.localParticipant?.isMicrophoneEnabled() ?? false;
    await _room?.localParticipant
        ?.setMicrophoneEnabled(!isEnabled);
  }

  bool get isMicEnabled =>
      _room?.localParticipant?.isMicrophoneEnabled() ?? false;

  // ─────────────────────────────────────────────
  //  CLEANUP
  // ─────────────────────────────────────────────
  Future<void> _cleanupRoom() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _listener?.dispose();
    _listener = null;

    try {
      await _room?.disconnect();
    } catch (_) {}

    _room = null;
  }

  // ─────────────────────────────────────────────
  //  DISCONNECT
  // ─────────────────────────────────────────────
  Future<void> disconnect() async {
    _isDisposed        = true;
    _reconnectAttempts = _maxReconnectAttempts;

    await _cleanupRoom();

    _currentRoomId = null;
    _currentUserId = null;
    _currentRole   = null;

    debugPrint("🔌 LiveKit disconnected cleanly");
  }

  // ─────────────────────────────────────────────
  //  RESET — screen reuse ke liye
  // ─────────────────────────────────────────────
  void reset() {
    _isDisposed        = false;
    _reconnectAttempts = 0;
  }
}
