import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebRTCService {

  WebSocketChannel? socket;

  RTCPeerConnection? peerConnection;

  MediaStream? localStream;

  Future init(String wsUrl) async {

    socket = WebSocketChannel.connect(Uri.parse(wsUrl));

  }

  Future createPeerConnection() async {

    final config = {
      "iceServers": [
        {
          "urls": "stun:stun.l.google.com:19302"
        }
      ]
    };

    peerConnection = await createPeerConnection(config);

  }

}
