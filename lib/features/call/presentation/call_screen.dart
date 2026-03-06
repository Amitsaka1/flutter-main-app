import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:app_project/core/utils/permission_helper.dart';
import 'package:app_project/core/network/api_client.dart';
import 'package:app_project/core/socket/global_socket_manager.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String callType;
  final String initialStatus;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.callType,
    required this.initialStatus,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  int? _remoteUid;
  StreamSubscription? _socketSub;

  Timer? _timer;
  int _seconds = 0;

  String callStatus = "RINGING";
  bool _callConnected = false;
  bool _callEnded = false;

  @override
  void initState() {
    super.initState();

    callStatus = widget.initialStatus;

    if (callStatus == "CONNECTED") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onCallAccepted();
      });
    }

    if (callStatus == "OFFLINE") {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    _socketSub =
        GlobalSocketManager.instance.messages.listen((data) {

      if (data["type"] == "CALL_ACCEPTED") {
        _onCallAccepted();
      }

      if (data["type"] == "CALL_REJECTED") {
        _onCallRejected();
      }

      if (data["type"] == "CALL_CANCELLED" ||
          data["type"] == "CALL_MISSED") {
        _onCallCancelled();
      }

      if (data["type"] == "CALL_ENDED") {
        _leaveCall(remote: true);
      }

      if (data["type"] == "CALL_ENDED_LOW_BALANCE") {
        _leaveCall(remote: true);
      }
    });
  }

  // ===============================
  // 🔥 CALL ACCEPTED
  // ===============================

  Future<void> _onCallAccepted() async {
    if (_callConnected) return;

    setState(() {
      callStatus = "Connected";
      _callConnected = true;
    });

    await _initAgora();
    _startTimer();
  }

  // ===============================
  // 🔥 CALL REJECTED
  // ===============================

  void _onCallRejected() {
    setState(() {
      callStatus = "Rejected";
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  // ===============================
  // 🔥 CALL CANCELLED / MISSED
  // ===============================

  void _onCallCancelled() {
    setState(() {
      callStatus = "Cancelled";
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  // ===============================
  // 🔥 INIT AGORA ONLY AFTER ACCEPT
  // ===============================

  Future<void> _initAgora() async {
    final granted =
        await PermissionHelper.requestCallPermissions();
    if (!granted) return;

    final response = await ApiClient.post("/call/token", {
      "channelName": widget.channelName
    });

    final token = response["token"];
    final appId = response["appId"];
    final uid = response["uid"];

    if (_engine == null) {
      _engine = createAgoraRtcEngine();
    }

    await _engine!.initialize(
      RtcEngineContext(appId: appId),
    );

    await _engine!.setChannelProfile(
      ChannelProfileType.channelProfileCommunication,
    );

    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 640, height: 360),
      frameRate: 15,
      bitrate: 800,
      orientationMode: OrientationMode.orientationModeAdaptive,
    ),
   );

    await _engine!.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );

    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(

        // 🔥 Remote user joined
        onUserJoined: (connection, remoteUid, elapsed) {
           if (!mounted) return;

          setState(() {
            _remoteUid = remoteUid;
          });
        },

        // 🔥 Remote user left
        onUserOffline: (connection, remoteUid, reason) {
          _leaveCall(remote: true);
        },

        // 🔥 Network lost
        onConnectionLost: (connection) {
          print("⚠ Agora connection lost");
        },

        // 🔥 Network unstable
        onConnectionInterrupted: (connection) {
          print("⚠ Network unstable");
        },

        // 🔥 Connection state changes
        onConnectionStateChanged: (connection, state, reason) {

          if (state == ConnectionStateType.connectionStateReconnecting) {
            print("🔄 Reconnecting to call...");
          }

          if (state == ConnectionStateType.connectionStateConnected) {
            print("✅ Call connection restored");
          }

          if (state == ConnectionStateType.connectionStateDisconnected) {
            _leaveCall(remote: true);
          }
        },
      ),
    );

    if (widget.callType == "VOICE_CALL") {
      await _engine!.enableAudio();
      await _engine!.disableVideo();
    } else {
      await _engine!.enableVideo();
      await _engine!.enableDualStreamMode(enabled: true);
      await _engine!.setRemoteSubscribeFallbackOption(
      StreamFallbackOptions.streamFallbackOptionAudioOnly,
    );
      await _engine!.startPreview();
    }

    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: uid,
      options: ChannelMediaOptions(
        publishCameraTrack: widget.callType == "VIDEO_CALL",
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );
    await _engine!.setEnableSpeakerphone(true);
    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
  }

  // ===============================
  // 🔥 TIMER START
  // ===============================

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;
        setState(() => _seconds++);
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  // ===============================
  // 🔥 LEAVE CALL
  // ===============================

  Future<void> _leaveCall({bool remote = false}) async {

  if (_callEnded) return;
  _callEnded = true;

  _timer?.cancel();

  try {

    if (!remote) {
      if (!_callConnected) {
        await ApiClient.post("/call/cancel", {
          "sessionId": widget.channelName
        });
      } else {
        await ApiClient.post("/call/end", {
          "sessionId": widget.channelName
        });
      }
    }

  } catch (_) {}

  if (_engine != null) {
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
  }
    
  if (mounted) Navigator.pop(context);
  }
  
  @override
  void dispose() {
    _socketSub?.cancel();
    _timer?.cancel();

    if (_engine != null) {
      _engine!.release();
      _engine = null;
    }

    super.dispose();
  }

  // ===============================
  // 🔥 UI
  // ===============================

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  backgroundColor: Colors.black,
  body: Stack(
  children: [

       // 🔥 Remote video (full screen)
      if (_callConnected &&
          widget.callType == "VIDEO_CALL" &&
          _remoteUid != null &&
          _engine != null)
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine!,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(
              channelId: widget.channelName,
            ),
          ),
        ),

      // 🔥 Local camera preview (small window)
       if (_callConnected &&
          widget.callType == "VIDEO_CALL" &&
          _engine != null)
        Positioned(
          top: 60,
           right: 20,
          child: SizedBox(
            width: 120,
            height: 160,
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: VideoCanvas(
                  uid: 0,
                  renderMode: RenderModeType.renderModeHidden,
                ),
              ),
            ),
          ),
        ),

      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
  
            Text(
              callStatus == "OFFLINE"
                  ? "User Offline"
                  : callStatus == "RINGING"
                      ? "Ringing..."
                      : callStatus,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 20),

            if (_callConnected)
              Text(
                _formatTime(_seconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 40),

            FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () => _leaveCall(),
              child: const Icon(Icons.call_end),
            ),
          ],
        ),
      ),
    ],
  ),

  );
  }
