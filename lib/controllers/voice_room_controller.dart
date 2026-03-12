import '../services/webrtc_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class VoiceRoomController {

  final WebRTCService webrtc = WebRTCService();

  String? roomId;
  String? userId;
  String? transportId;

  // =========================
  // JOIN ROOM
  // =========================
  Future joinRoom(String rId, String uId, String wsUrl) async {

    roomId = rId;
    userId = uId;

    if (kIsWeb) {
      print("Web mode: WebRTC disabled");
      return;
     }

    await webrtc.init(wsUrl);

    await webrtc.createPeer();

    webrtc.createTransport(roomId!, userId!);

    webrtc.socket?.stream.listen((message) {

        final data = jsonDecode(message);

        // 🔊 new speaker audio
        if (data["type"] == "NEW_PRODUCER") {

          listenSpeaker(
            data["producerId"],
            data["rtpCapabilities"] ?? {}
          );

        }

      });

   }

  // =========================
  // CONNECT TRANSPORT
  // =========================
  void connectTransport(String tId, dynamic dtls) {

    transportId = tId;

    webrtc.connectTransport(tId, dtls);

  }

  // =========================
  // START SPEAKING
  // =========================
  Future startSpeaking() async {

    if (transportId == null) return;

    await webrtc.startProducingAudio(transportId!);

  }

  // =========================
  // LISTEN AUDIO
  // =========================
  void listenSpeaker(
      String producerId,
      dynamic rtpCapabilities
      ) {

    if (transportId == null) return;

    webrtc.consumeAudio(
        roomId!,
        transportId!,
        producerId,
        rtpCapabilities
    );

  }

}
