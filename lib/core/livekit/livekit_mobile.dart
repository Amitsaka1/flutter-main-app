import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../socket/global_socket_manager.dart';

class LiveKitService {
  Room? _room;

  Room? get room => _room;

  Future<void> connect({
    required String userId,
    required String roomId,
    required String role,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("https://momo-qd13.onrender.com/livekit/token"),
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

      if (_room != null &&
          _room!.connectionState == ConnectionState.connected) {
        return;
      }

      final room = Room();

      await room.connect(
        "wss://acceptable-marleen-amitsaka12345-ddc0c198.koyeb.app",
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      room.events.listen((event) {
        if (event is TrackSubscribedEvent) {
          final track = event.track;
          if (track is RemoteAudioTrack) {
            track.start();
          }
        }
      });

      if (role == "speaker") {
        await room.localParticipant?.setMicrophoneEnabled(true);
      } else {
        await room.localParticipant?.setMicrophoneEnabled(false);
      }

      _room = room;

      GlobalSocketManager.instance.joinRoom(roomId);

    } catch (e) {
      rethrow;
    }
  }

  Future<void> enableMic() async {
    await _room?.localParticipant?.setMicrophoneEnabled(true);
  }

  Future<void> disableMic() async {
    await _room?.localParticipant?.setMicrophoneEnabled(false);
  }

  Future<void> disconnect({String? roomId}) async {
    if (roomId != null) {
      GlobalSocketManager.instance.leaveRoom(roomId);
    }
    await _room?.disconnect();
    _room = null;
  }
}
