import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveKitService {
  Room? _room;

  Room? get room => _room;

  /// =========================
  /// 🔥 CONNECT (FINAL STABLE + ADAPTIVE)
  /// =========================
  Future<void> connect({
    required String userId,
    required String roomId,
    required String role,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("https://momo-1etm.onrender.com/livekit/token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "roomId": roomId,
          "role": role,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["success"] != true) {
        throw Exception("Token failed");
      }

      final token = data["token"];

      // 🔥 prevent duplicate connect
      if (_room != null &&
          _room!.connectionState == ConnectionState.connected) {
        print("⚠️ Already connected");
        return;
      }

      final room = Room();

      /// 🔥 DEFAULT SAFE BITRATE (balanced for scale)
      const int bitrate = 64000;

      await room.connect(
        "wss://acceptable-marleen-amitsaka12345-ddc0c198.koyeb.app",
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(
            name: 'microphone',
            bitrate: 64000, // 🔥 fixed safe bitrate
            dtx: true, // 🔥 silence bandwidth save
          ),
        ),
      );

      /// 🔥 SPEAKER OUTPUT
      await room.setSpeakerphoneOn(true);

      /// 🔥 ADAPTIVE RECEIVE
      room.setAdaptiveStream(true);

      /// 🔥 AUDIO RECEIVE FIX
      room.events.listen((event) {
        if (event is TrackSubscribedEvent) {
          final track = event.track;

          if (track is RemoteAudioTrack) {
            track.start();
          }
        }
      });

      /// 🔥 DEFAULT: MIC OFF (listener safe)
      if (role == "speaker") {
        await room.localParticipant?.setMicrophoneEnabled(true);
      } else {
        await room.localParticipant?.setMicrophoneEnabled(false);
      }

      _room = room;

      print("✅ LiveKit Connected (FINAL STABLE)");

    } catch (e) {
      print("❌ LiveKit Error: $e");
      rethrow;
    }
  }

  /// =========================
  /// 🔥 MIC CONTROL (ROLE BASED)
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
