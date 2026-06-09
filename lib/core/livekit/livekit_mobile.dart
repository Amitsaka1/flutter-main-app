import 'package:flutter_webrtc/flutter_webrtc.dart'
    show RTCConfiguration, RTCIceServer;
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

  // ✅ FIX (NEW): Voice World token store karo reconnect ke liye
  //
  // Problem: connectWithToken() mein _currentUserId = null set hota tha
  //          _scheduleReconnect() mein sirf _currentUserId != null check tha
  //          Matlab Voice World mein disconnect ho → reconnect KABHI nahi hota
  //          User ko manually room se bahar jaake wapas aana padta tha
  //
  // Fix: Token store karo — reconnect pe wahi token use karo
  //
  String? _currentToken; // ✅ NEW — Voice World reconnect ke liye

  bool _isConnecting = false;
  bool _isDisposed   = false;

  Timer? _reconnectTimer;
  int    _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  EventsListener<RoomEvent>? _listener;

  // ── Public getters — ✅ UNCHANGED ─────────────
  Room? get room        => _room;
  bool  get isConnected =>
      _room?.connectionState == ConnectionState.connected;

  // ─────────────────────────────────────────────
  //  CONNECT — 1:1 calls ke liye — ✅ UNCHANGED
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
    _currentToken  = null; // ✅ FIX: 1:1 call mein stored token clear karo

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
  //  CONNECT WITH TOKEN — Voice World ke liye
  //  FIXED: Token ab store hota hai reconnect ke liye
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
    _currentUserId = null;

    // ✅ FIX: Token store karo — reconnect mein kaam aayega
    // Pehle ye line nahi thi — isliye reconnect hamesha fail hota tha
    _currentToken = token; // ✅ NEW

    try {

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
  //  SHARED CONNECT LOGIC — ✅ UNCHANGED
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
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl:  true,
        ),
        defaultAudioOutputOptions: AudioOutputOptions(
          speakerOn: true,
        ),
      ),
    );

    await room.connect(
      Environment.livekitUrl,
      token,
      connectOptions: ConnectOptions(
        autoSubscribe: true,
        rtcConfiguration: RTCConfiguration(
          iceServers: [
            RTCIceServer(
              urls: ['stun:stun.relay.metered.ca:80'],
            ),
            RTCIceServer(
              urls: ['turn:global.relay.metered.ca:80'],
              username:   Environment.turnUsername,
              credential: Environment.turnCredential,
            ),
            RTCIceServer(
              urls: ['turn:global.relay.metered.ca:80?transport=tcp'],
              username:   Environment.turnUsername,
              credential: Environment.turnCredential,
            ),
            RTCIceServer(
              urls: ['turn:global.relay.metered.ca:443'],
              username:   Environment.turnUsername,
              credential: Environment.turnCredential,
            ),
            RTCIceServer(
              urls: ['turns:global.relay.metered.ca:443?transport=tcp'],
              username:   Environment.turnUsername,
              credential: Environment.turnCredential,
            ),
          ],
        ),
      ),
    );

    if (_isDisposed) {
      await room.disconnect();
      return;
    }

    _room              = room;
    _reconnectAttempts = 0;

    _setupListeners(role: role);

    if (role == "speaker") {
      await room.localParticipant?.setMicrophoneEnabled(true);
    } else {
      await room.localParticipant?.setMicrophoneEnabled(false);
    }

    debugPrint("✅ LiveKit connected: $_currentRoomId ($role)");
  }

  // ─────────────────────────────────────────────
  //  SETUP LISTENERS — ✅ UNCHANGED
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

        if (role == "speaker") {
          await _room?.localParticipant
              ?.setMicrophoneEnabled(true);
        }
      })

      ..on<RoomDisconnectedEvent>((event) {
        debugPrint("❌ LiveKit disconnected: ${event.reason}");

        if (event.reason != DisconnectReason.clientInitiated &&
            !_isDisposed) {
          _scheduleReconnect();
        }
      });
  }

  // ─────────────────────────────────────────────
  //  FETCH TOKEN — 1:1 calls ke liye — ✅ UNCHANGED
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
      throw Exception("LiveKit token failed: ${data["message"]}");
    }

    return data["token"];
  }

  // ─────────────────────────────────────────────
  //  RECONNECT — FIXED
  // ─────────────────────────────────────────────
  void _scheduleReconnect() {

    if (_isDisposed)   return;
    if (_currentRoomId == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint("❌ Max reconnect attempts reached");
      return;
    }

    _reconnectTimer?.cancel();

    // ✅ UNCHANGED: Exponential backoff
    final delay = Duration(
      seconds: (_reconnectAttempts < 4)
          ? (2 * (_reconnectAttempts + 1))
          : 30,
    );

    _reconnectAttempts++;

    debugPrint("🔄 Reconnect #$_reconnectAttempts in ${delay.inSeconds}s");

    _reconnectTimer = Timer(delay, () async {
      if (_isDisposed) return;
      try {

        if (_currentUserId != null) {
          // ✅ UNCHANGED: 1:1 call reconnect
          await connect(
            userId: _currentUserId!,
            roomId: _currentRoomId!,
            role:   _currentRole!,
          );

        } else if (_currentToken != null) {
          // ✅ FIX: Voice World reconnect
          //
          // Problem: Pehle ye block nahi tha
          //          _currentUserId = null hota tha Voice World mein
          //          Toh reconnect silently skip ho jaata tha
          //          User ka audio band ho jaata tha permanently
          //
          // Fix: _currentToken store kiya (connectWithToken mein)
          //      Wahi token se dobara connect karo
          //
          await connectWithToken(        // ✅ NEW
            token:  _currentToken!,
            roomId: _currentRoomId!,
            role:   _currentRole!,
          );
        }

      } catch (_) {}
    });
  }

  // ─────────────────────────────────────────────
  //  MIC CONTROLS — ✅ UNCHANGED
  // ─────────────────────────────────────────────
  Future<void> enableMic() async {
    await _room?.localParticipant?.setMicrophoneEnabled(true);
  }

  Future<void> disableMic() async {
    await _room?.localParticipant?.setMicrophoneEnabled(false);
  }

  Future<void> toggleMic() async {
    final isEnabled =
        _room?.localParticipant?.isMicrophoneEnabled() ?? false;
    await _room?.localParticipant?.setMicrophoneEnabled(!isEnabled);
  }

  bool get isMicEnabled =>
      _room?.localParticipant?.isMicrophoneEnabled() ?? false;

  // ─────────────────────────────────────────────
  //  CLEANUP — ✅ UNCHANGED
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
  //  DISCONNECT — FIXED
  // ─────────────────────────────────────────────
  Future<void> disconnect() async {
    _isDisposed        = true;
    _reconnectAttempts = _maxReconnectAttempts;

    await _cleanupRoom();

    _currentRoomId = null;
    _currentUserId = null;
    _currentRole   = null;
    _currentToken  = null; // ✅ FIX: Token bhi clear karo

    debugPrint("🔌 LiveKit disconnected cleanly");
  }

  // ─────────────────────────────────────────────
  //  RESET — ✅ UNCHANGED
  // ─────────────────────────────────────────────
  void reset() {
    _isDisposed        = false;
    _reconnectAttempts = 0;
  }
}
