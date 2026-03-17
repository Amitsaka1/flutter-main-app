import '../services/webrtc_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class VoiceRoomController {

  final WebRTCService webrtc = WebRTCService();

  String? roomId;
  String? userId;
  String? transportId;

  bool _joined = false;
  bool _socketListening = false;

  dynamic routerCapabilities;

  // =========================
  // JOIN ROOM
  // =========================
  Future joinRoom(String rId, String uId, String wsUrl) async {

    if (_joined) {
      print("Voice already connected");
      return;
    }

    roomId = rId;
    userId = uId;

    if (kIsWeb) {
      print("Web mode: WebRTC disabled");
      return;
    }

    _joined = true;

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

    // =========================
    // SOCKET LISTENER
    // =========================
    if (!_socketListening) {

      _socketListening = true;

      webrtc.socket?.stream.listen((message) {

        final data = jsonDecode(message);
        final type = data["type"];

        print("VOICE SOCKET EVENT: $type");

        if (type == "TRANSPORT_CREATED") {

          print("TRANSPORT CREATED");

          final transport = data["transport"];
          final tId = transport["transportId"];
          final params = transport["params"];

          transportId = tId;

          /// 🔥 CONNECT TRANSPORT
          connectTransport(
            tId,
            params["dtlsParameters"],
          );
        }

        if (type == "ROUTER_RTP_CAPABILITIES") {

          print("ROUTER CAPABILITIES RECEIVED");

          routerCapabilities = data["rtpCapabilities"];
        }

        if (type == "TRANSPORT_CONNECTED") {
          print("TRANSPORT CONNECTED");
        }

        if (type == "PRODUCER_CREATED") {
          print("AUDIO PRODUCER CREATED");
        }

        if (type == "CONSUMER_CREATED") {

          final consumer = data["consumer"];

          print("AUDIO CONSUMER CREATED: ${consumer["id"]}");
        }

        // =========================
        // NEW SPEAKER
        // =========================
        if (type == "NEW_PRODUCER") {

          print("NEW SPEAKER JOINED");

          if (routerCapabilities == null) return;

          listenSpeaker(
            data["producerId"],
            routerCapabilities,
          );
        }

        // =========================
        // EXISTING SPEAKERS
        // =========================
        if (type == "EXISTING_PRODUCERS") {

          final producers = data["producers"];

          if (routerCapabilities == null) return;

          for (final producerId in producers) {

            listenSpeaker(
              producerId,
              routerCapabilities,
            );
          }
        }

      }); // ✅ FIX: listen properly closed

    } // ✅ FIX: if (_socketListening) properly closed

  } // ✅ FIX: joinRoom properly closed

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

    if (transportId == null) {

      /// wait for transport
      await Future.delayed(const Duration(milliseconds: 300));

      if (transportId == null) return;
    }

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

  // =========================
  // RESET VOICE STATE
  // =========================
  void reset() {

    _joined = false;
    _socketListening = false;

    transportId = null;
    routerCapabilities = null;

  }

}
