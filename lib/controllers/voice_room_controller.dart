import '../services/webrtc_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/debug/app_debug.dart';
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
      AppDebug.log("[VOICE] Already connected (skip join)");
      return;
    }

    roomId = rId;
    userId = uId;

    AppDebug.log("[VOICE] Joining room: $roomId as user: $userId");

    if (kIsWeb) {
      AppDebug.log("[VOICE] Web mode detected → WebRTC disabled");
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

        AppDebug.log("[VOICE] EVENT: $type");

        if (type == "TRANSPORT_CREATED") {

          AppDebug.log("[VOICE] TRANSPORT CREATED");

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

          AppDebug.log("[VOICE] ROUTER CAPABILITIES RECEIVED");

          routerCapabilities = data["rtpCapabilities"];
        }

        if (type == "TRANSPORT_CONNECTED") {
          AppDebug.log("[VOICE] TRANSPORT CONNECTED");
        }

        if (type == "PRODUCER_CREATED") {
          AppDebug.log("[VOICE] AUDIO PRODUCER CREATED");
        }

        if (type == "CONSUMER_CREATED") {

          final consumer = data["consumer"];

          AppDebug.log("[VOICE] AUDIO CONSUMER CREATED");
        }

        // =========================
        // NEW SPEAKER
        // =========================
        if (type == "NEW_PRODUCER") {

          AppDebug.log("[VOICE] NEW SPEAKER JOINED");

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

            AppDebug.log("[VOICE] EXISTING SPEAKER: $producerId");

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

    AppDebug.log("[VOICE] CONNECTING TRANSPORT: $tId");

    transportId = tId;

    webrtc.connectTransport(tId, dtls);

  }

  // =========================
  // START SPEAKING
  // =========================
  Future startSpeaking() async {

  AppDebug.log("[VOICE] TRY START MIC"); // 🔥 ADD

  if (transportId == null) {

    AppDebug.log("[VOICE] transport not ready, waiting..."); // 🔥 ADD

    await Future.delayed(const Duration(milliseconds: 300));

    if (transportId == null) {
      AppDebug.log("[VOICE] FAILED: transport still null"); // 🔥 ADD
      return;
    }
  }

  AppDebug.log("[VOICE] STARTING AUDIO PRODUCER"); // 🔥 ADD

  await webrtc.startProducingAudio(transportId!);

  }

  // =========================
  // LISTEN AUDIO
  // =========================
  void listenSpeaker(
  String producerId,
  dynamic rtpCapabilities
) {

  if (transportId == null) {
    AppDebug.log("[VOICE] Cannot listen → transport null"); // 🔥 ADD
    return;
  }

  AppDebug.log("[VOICE] START LISTENING: $producerId"); // 🔥 ADD

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
