import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveKitService {
  Room? _room;

  Room? get room => _room;

  /// =========================
  /// 🔥 CONNECT
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

      await room.connect(
        "wss://acceptable-marleen-amitsaka12345-ddc0c198.koyeb.app",
        token,
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

      _room = room;

      print("✅ LiveKit Connected");

    } catch (e) {
      print("❌ LiveKit Connect Error: $e");
      rethrow;
    }
  }

  /// =========================
  /// 🔥 MIC CONTROL
  /// =========================
  Future<void> enableMic() async {
    await _room?.localParticipant?.setMicrophoneEnabled(true);
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
