import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebRTCService {

  WebSocketChannel? socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  // =========================
  // INIT SOCKET
  // =========================
  Future init(String wsUrl) async {
    socket = WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  // =========================
  // CREATE PEER CONNECTION
  // =========================
  Future createPeer() async {

    final config = {
      "iceServers": [
        {
          "urls": "stun:stun.l.google.com:19302"
        }
      ]
    };

    peerConnection = await createPeerConnection(config);
  }

  // =========================
  // CREATE TRANSPORT
  // =========================
  void createTransport(String roomId, String userId) {

    socket?.sink.add(jsonEncode({
      "type": "CREATE_WEBRTC_TRANSPORT",
      "roomId": roomId,
      "userId": userId
    }));

  }

  // =========================
  // CONNECT TRANSPORT
  // =========================
  void connectTransport(String transportId, dynamic dtlsParameters) {

    socket?.sink.add(jsonEncode({
      "type": "CONNECT_TRANSPORT",
      "transportId": transportId,
      "dtlsParameters": dtlsParameters
    }));

  }

  // =========================
  // PRODUCE AUDIO (Speaker)
  // =========================
  void produceAudio(String transportId, dynamic rtpParameters) {

    socket?.sink.add(jsonEncode({
      "type": "PRODUCE_AUDIO",
      "transportId": transportId,
      "rtpParameters": rtpParameters
    }));

  }

  // =========================
  // CONSUME AUDIO (Listener)
  // =========================
  void consumeAudio(
    String roomId,
    String transportId,
    String producerId,
    dynamic rtpCapabilities
  ) {

    socket?.sink.add(jsonEncode({
      "type": "CONSUME_AUDIO",
      "roomId": roomId,
      "transportId": transportId,
      "producerId": producerId,
      "rtpCapabilities": rtpCapabilities
    }));

  }

}
