import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebRTCService {

  WebSocketChannel? socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  final Map<String, MediaStream> remoteStreams = {};
  final Map<String, RTCVideoRenderer> renderers = {};

  // =========================
  // INIT SOCKET
  // =========================
  Future init(String wsUrl) async {

  socket = WebSocketChannel.connect(Uri.parse(wsUrl));

  socket?.stream.listen((message) {

    final data = jsonDecode(message);

    final type = data["type"];

    /// 🔥 SPEAKER LEFT
    if (type == "PRODUCER_CLOSED") {

      final producerId = data["producerId"];

      removeRemoteStream(producerId);

    }

  });

  }

  // =========================
  // CREATE PEER CONNECTION
  // =========================
  Future createPeer() async {

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
        final producerId = event.track.id ?? "";

        _playRemoteAudio(producerId, remoteStream);

      }

    };

  }

  // =========================
  // START MICROPHONE
  // =========================
  Future startMicrophone() async {

    final mediaConstraints = {
      "audio": {
        "echoCancellation": true,
        "noiseSuppression": true,
        "autoGainControl": true
      },
      "video": false
    };

    localStream = await navigator.mediaDevices.getUserMedia(
      mediaConstraints,
    );

    for (var track in localStream!.getTracks()) {
      peerConnection?.addTrack(track, localStream!);
    }

  }

  // =========================
  // GET RTP PARAMETERS
  // =========================
  Future<Map<String, dynamic>?> getRtpParameters() async {

  final senders = await peerConnection?.getSenders();

  if (senders == null) return null;

  for (var sender in senders) {

    if (sender.track?.kind == "audio") {

      /// mediasoup client side empty rtpParameters acceptable
      return {};

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
  // PRODUCE AUDIO
  // =========================
  void produceAudio(String transportId, dynamic rtpParameters) {

    socket?.sink.add(jsonEncode({
      "type": "PRODUCE_AUDIO",
      "transportId": transportId,
      "rtpParameters": rtpParameters
    }));

  }

  // =========================
  // CONSUME AUDIO
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

    print("REMOTE AUDIO RECEIVED FROM: $producerId");

    if (remoteStreams.containsKey(producerId)) return;

    remoteStreams[producerId] = stream;

    final renderer = RTCVideoRenderer();

    await renderer.initialize();

    renderer.srcObject = stream;

    renderers[producerId] = renderer;

  }

void removeRemoteStream(String producerId) {

  final stream = remoteStreams.remove(producerId);
  final renderer = renderers.remove(producerId);

  renderer?.srcObject = null;
  renderer?.dispose();

  stream?.dispose();

}
}
