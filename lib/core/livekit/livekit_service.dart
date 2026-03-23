import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveKitService {
  Room? _room;

  Room? get room => _room;

  /// =========================
  /// 🔥 CONNECT (ULTRA AUDIO)
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

      final room = Room();

      /// 🔥 ULTRA QUALITY CONNECT
      await room.connect(
        "wss://acceptable-marleen-amitsaka12345-ddc0c198.koyeb.app",
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(
            name: 'microphone',
            bitrate: 64000, // 🔥 HIGH QUALITY AUDIO
          ),
        ),
      );

      /// 🔥 AUDIO RECEIVE FIX (IMPORTANT)
      room.events.listen((event) {
        if (event is TrackSubscribedEvent) {
          final track = event.track;

          if (track is RemoteAudioTrack) {
            track.start();
          }
        }
      });

      /// 🔥 MIC ENABLE WITH FULL PROCESSING
      await room.localParticipant?.setMicrophoneEnabled(
        true,
        captureOptions: const AudioCaptureOptions(
          echoCancellation: true,   // 🔥 echo remove
          noiseSuppression: true,   // 🔥 noise remove
          autoGainControl: true,    // 🔥 auto volume balance
        ),
      );

      _room = room;

      print("✅ LiveKit Connected (ULTRA AUDIO)");

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
      ),
    );
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
