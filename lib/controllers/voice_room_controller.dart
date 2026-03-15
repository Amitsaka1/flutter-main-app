import '../services/webrtc_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class VoiceRoomController {

  final WebRTCService webrtc = WebRTCService();

  String? roomId;
  String? userId;
  String? transportId;

  dynamic routerCapabilities;

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

    /// 🔥 JOIN ROOM SOCKET (IMPORTANT)
    webrtc.socket?.sink.add(jsonEncode({
      "type": "JOIN_ROOM_SOCKET",
      "roomId": roomId,
    }));

     await webrtc.createPeer();

     /// 🔥 REQUEST ROUTER RTP CAPABILITIES
     webrtc.socket?.sink.add(jsonEncode({
       "type": "GET_ROUTER_RTP_CAPABILITIES",
       "roomId": roomId
     }));

     /// 🔥 CREATE TRANSPORT
     webrtc.createTransport(roomId!, userId!);

     webrtc.socket?.stream.listen((message) {

      final data = jsonDecode(message);

      final type = data["type"];

      if (type == "TRANSPORT_CREATED") {

        final transport = data["transport"];

        final tId = transport["transportId"];

        transportId = tId;

      }

      if (type == "ROUTER_RTP_CAPABILITIES") {

        routerCapabilities = data["rtpCapabilities"];

        print("Router RTP capabilities received");

      }

      // =========================
      // TRANSPORT CONNECTED
      // =========================
      if (type == "TRANSPORT_CONNECTED") {

         print("Transport connected");

      }

      // =========================
      // PRODUCER CREATED
      // =========================
      if (type == "PRODUCER_CREATED") {

        print("Audio producer created");

      }

      // =========================
      // CONSUMER CREATED
      // =========================
       if (type == "CONSUMER_CREATED") {

        final consumer = data["consumer"];

        print("Consumer created: ${consumer["id"]}");

      }

      // =========================
      // NEW SPEAKER
      // =========================
      if (type == "NEW_PRODUCER") {

        if (routerCapabilities == null) return;

        listenSpeaker(
          data["producerId"],
          routerCapabilities
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
