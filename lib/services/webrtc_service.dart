import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebRTCService {

  WebSocketChannel? socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  final Map<String, MediaStream> remoteStreams = {};
}

  // =========================
  // INIT SOCKET
  // =========================
  Future init(String wsUrl) async {

  socket = WebSocketChannel.connect(Uri.parse(wsUrl));

  socket?.stream.listen((message) {

    final data = jsonDecode(message);

    if (data["type"] == "TRANSPORT_CREATED") {

      final transport = data["transport"];

      final transportId = transport["transportId"];

      final params = transport["params"];

      connectTransport(
        transportId,
        params["dtlsParameters"],
      );

    }

  });

  }

  // =========================
  // CREATE PEER CONNECTION
  // =========================
  final config = {
    "sdpSemantics": "unified-plan",
    "bundlePolicy": "max-bundle",
    "rtcpMuxPolicy": "require",
    "iceServers": [
     {
        "urls": "stun:stun.l.google.com:19302"
      }
    ]
  };

    peerConnection = await createPeerConnection(config);

    peerConnection?.onTrack = (RTCTrackEvent event) {

      if (event.track.kind == "audio") {

        final remoteStream = event.streams[0];

        final producerId = event.track.id;

        _playRemoteAudio(producerId, remoteStream);

      }

    };
  }

  // =========================
  // START MICROPHONE
  // =========================
  Future startMicrophone() async {

    final mediaConstraints = {
      "audio": true,
      "video": false
    };

    localStream = await navigator.mediaDevices.getUserMedia(
      mediaConstraints,
    );

    localStream!.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

  }

  // =========================
  // GET RTP PARAMETERS
  // =========================
  Future<Map<String, dynamic>?> getRtpParameters() async {

    final senders = await peerConnection?.getSenders();

    if (senders == null) return null;

    for (var sender in senders) {

      if (sender.track?.kind == "audio") {

        final params = await sender.getParameters();

        return params.toMap();
      }
    }

    return null;
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
      dynamic rtpCapabilities) {

    socket?.sink.add(jsonEncode({
      "type": "CONSUME_AUDIO",
      "roomId": roomId,
      "transportId": transportId,
      "producerId": producerId,
      "rtpCapabilities": rtpCapabilities
    }));

  }

  // =========================
  // START PRODUCING AUDIO
  // =========================
  Future startProducingAudio(String transportId) async {

    await startMicrophone();

    final rtp = await getRtpParameters();

    if (rtp != null) {
      produceAudio(transportId, rtp);
    }

  }

  // =========================
  // PLAY REMOTE AUDIO
  // =========================
  void _playRemoteAudio(String producerId, MediaStream stream) async {

  if (remoteStreams.containsKey(producerId)) {
    return;
  }

  remoteStreams[producerId] = stream;

  final renderer = RTCVideoRenderer();

  await renderer.initialize();

  renderer.srcObject = stream;

  }

}
