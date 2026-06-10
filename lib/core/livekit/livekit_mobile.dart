// fix: flutter_webrtc import REMOVED — TURN hataya
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';          // new: WidgetsBindingObserver
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:app_project/core/config/environment.dart';

// modify: WidgetsBindingObserver add kiya — AppLifecycle ke liye
class LiveKitService with WidgetsBindingObserver {

  Room?   _room;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentRole;
  String? _currentToken;

  bool _isConnecting = false;
  bool _isDisposed   = false;

  Timer? _reconnectTimer;
  int    _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  EventsListener<RoomEvent>? _listener;

  // new: VoiceRoomNotifier isko set karega — reconnect ke baad listeners reload
  VoidCallback? onReconnected;

  // new: Constructor — AppLifecycle observer register karo
  LiveKitService() {
    WidgetsBinding.instance.addObserver(this);
  }

  // new: App kill/detach pe room disconnect karo
  // Fix #12: App close without leave → seat stuck
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.detached &&
        !_isDisposed &&
        _room != null) {
      disconnect();
    }
  }

  // ── Public getters — unchanged ─────────────
  Room? get room        => _room;
  bool  get isConnected =>
      _room?.connectionState == ConnectionState.connected;

  // ─────────────────────────────────────────────
  //  CONNECT — 1:1 calls — unchanged
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
    _currentToken  = null;

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
  //  CONNECT WITH TOKEN — Voice World
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
    _currentToken  = token;

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
      // modify: _scheduleReconnect() HATAYA — timer ka catch ab handle karega
      // pehle yahan tha — double scheduling hoti thi
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  // ─────────────────────────────────────────────
  //  CONNECT TO ROOM — TURN config HATAYA
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

    // modify: pura rtcConfiguration block HATAYA
    // Fix #11: Metered.ca TURN remove — LiveKit ka built-in use hoga
    // pehle: 5 custom ICE servers tha jo US/EU relay se jaata tha
    // ab: LiveKit apne TURN credentials khud handle karta hai
    await room.connect(
      Environment.livekitUrl,
      token,
      connectOptions: const ConnectOptions(autoSubscribe: true),
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
  //  SETUP LISTENERS — unchanged
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
          await _room?.localParticipant?.setMicrophoneEnabled(true);
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
  //  FETCH TOKEN — 1:1 calls — unchanged
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
  //  RECONNECT — 2 fixes
  // ─────────────────────────────────────────────
  void _scheduleReconnect() {

    if (_isDisposed)    return;
    if (_currentRoomId == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint("❌ Max reconnect attempts reached");
      return;
    }

    _reconnectTimer?.cancel();

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
          await connect(
            userId: _currentUserId!,
            roomId: _currentRoomId!,
            role:   _currentRole!,
          );
        } else if (_currentToken != null) {
          await connectWithToken(
            token:  _currentToken!,
            roomId: _currentRoomId!,
            role:   _currentRole!,
          );
        }

        // new: Fix #3 — reconnect success ke baad VoiceRoomNotifier ko notify karo
        // taaki woh naye Room pe listeners reload kare aur members refresh kare
        onReconnected?.call();

      } catch (_) {
        // modify: Fix #2 — retry karo silently fail mat karo
        // pehle: catch (_) {} → reconnect permanently band ho jaata tha
        // ab: dobara schedule karo — attempts limit tak
        _scheduleReconnect();
      }
    });
  }

  // ─────────────────────────────────────────────
  //  MIC CONTROLS — unchanged
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
  //  CLEANUP — unchanged
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
  //  DISCONNECT — expectedRoomId add kiya
  //  Fix #5: Singleton dispose conflict fix
  // ─────────────────────────────────────────────
  Future<void> disconnect({String? expectedRoomId}) async {

    // modify: Fix #5 — roomId mismatch pe skip karo
    // Problem: LiveKitService singleton hai — Group A ka dispose
    //          Group B ka active connection kill kar sakta tha
    // Fix: Sirf tab disconnect karo jab room match kare
    if (expectedRoomId != null &&
        _currentRoomId  != null &&
        _currentRoomId  != expectedRoomId) {
      debugPrint("⚠️ Disconnect skipped — room mismatch");
      return;
    }

    _isDisposed        = true;
    _reconnectAttempts = _maxReconnectAttempts;

    await _cleanupRoom();

    _currentRoomId = null;
    _currentUserId = null;
    _currentRole   = null;
    _currentToken  = null;

    debugPrint("🔌 LiveKit disconnected cleanly");
  }

  // ─────────────────────────────────────────────
  //  RESET — unchanged
  // ─────────────────────────────────────────────
  void reset() {
    _isDisposed        = false;
    _reconnectAttempts = 0;
  }
}
