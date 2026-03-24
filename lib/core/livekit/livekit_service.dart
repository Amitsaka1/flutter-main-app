import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

class LiveKitService {
  Room? _room;

  Room? get room => _room;

  /// =========================
  /// 🔥 AUTO BITRATE SYSTEM
  /// =========================
  Future<int> _getAdaptiveBitrate() async {
    final connectivity = await Connectivity().checkConnectivity();

    // 🔥 BEST NETWORK (WiFi / Ethernet)
    if (connectivity == ConnectivityResult.wifi ||
        connectivity == ConnectivityResult.ethernet) {
      return 96000;
    }

    // 🔥 NORMAL (Mobile Data)
    if (connectivity == ConnectivityResult.mobile) {
      return 64000;
    }

    // 🔥 LOW / UNKNOWN
    return 32000;
  }

  /// =========================
  /// 🔥 CONNECT (ULTRA + ADAPTIVE)
  /// =========================
  Future<void> connect({
    required String userId,
    required String roomId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("https://momo-1etm.onrender.com/livekit/token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "roomId": roomId,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["success"] != true) {
        throw Exception("Token failed");
      }

      final token = data["token"];

      // 🔥 prevent duplicate reconnect
      if (_room != null &&
          _room!.connectionState == ConnectionState.connected) {
        print("⚠️ Already connected, skipping reconnect");
        return;
      }

      // 🔥 AUTO BITRATE
      final bitrate = await _getAdaptiveBitrate();
      print("🎯 Using bitrate: $bitrate");

      final room = _room ?? Room();

      await room.connect(
        "wss://acceptable-marleen-amitsaka12345-ddc0c198.koyeb.app",
        token,
        roomOptions: RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(
            name: 'microphone',
            bitrate: bitrate, // 🔥 dynamic bitrate
          ),
        ),
      );

      /// 🔥 AUDIO RECEIVE FIX
      room.events.listen((event) {
        if (event is TrackSubscribedEvent) {
          final track = event.track;

          if (track is RemoteAudioTrack) {
            track.start();
          }
        }
      });

      /// 🔥 MIC ENABLE (ULTRA PROCESSING)
      await room.localParticipant?.setMicrophoneEnabled(
        true,
        captureOptions: const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
          typingNoiseDetection: true,
        ),
      );

      _room = room;

      print("✅ LiveKit Connected (ULTRA ADAPTIVE AUDIO)");

    } catch (e) {
      print("❌ LiveKit Connect Error: $e");
      rethrow;
    }
  }

  /// =========================
  /// 🔥 MIC CONTROL
  /// =========================
  Future<void> enableMic() async {
    await _room?.localParticipant?.setMicrophoneEnabled(
      true,
      captureOptions: const AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
        typingNoiseDetection: true,
      ),
    );
  }

  /// =========================
  /// 🔥 REAL-TIME BITRATE SWITCH
  /// =========================
  Future<void> switchBitrate(int newBitrate) async {
    if (_room == null) return;

    try {
      final participant = _room!.localParticipant;
      if (participant == null) return;

      // 🔥 mic off (old track remove)
      await participant.setMicrophoneEnabled(false);

      // 🔥 mic on with new bitrate
      await participant.setMicrophoneEnabled(
        true,
        captureOptions: const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
          typingNoiseDetection: true,
        ),
        publishOptions: AudioPublishOptions(
          bitrate: newBitrate,
          name: 'microphone',
        ),
      );

      print("🎯 Bitrate switched to $newBitrate");

    } catch (e) {
      print("❌ Bitrate switch error: $e");
    }
  }

  Future<void> disableMic() async {
    await _room?.localParticipant?.setMicrophoneEnabled(false);
  }

  /// =========================
  /// 🔥 DISCONNECT
  /// =========================
  Future<void> disconnect() async {
    await _room?.disconnect();
    _room = null;
  }
}
