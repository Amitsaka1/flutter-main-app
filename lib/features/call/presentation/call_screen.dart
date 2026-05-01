import 'dart:async';
//import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:app_project/core/utils/permission_helper.dart';
import 'package:app_project/core/network/api_client.dart';
import 'package:app_project/core/socket/global_socket_manager.dart';
import 'package:flutter/foundation.dart';

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
  dynamic _engine; // 🔥 FIXED (was RtcEngine)
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

      if (data["type"] == "CALL_ENDED" ||
          data["type"] == "CALL_ENDED_LOW_BALANCE") {
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

    if (!kIsWeb) {
      await _initAgora();
    }

    _startTimer();
  }

  // ===============================
  // 🔥 INIT AGORA
  // ===============================

  Future<void> _initAgora() async {
    if (kIsWeb) return; // 🔥 CRITICAL

    final granted =
        await PermissionHelper.requestCallPermissions();
    if (!granted) return;

    final response = await ApiClient.post("/call/token", {
      "channelName": widget.channelName
    });

    final token = response["token"];
    final appId = response["appId"];
    final uid = response["uid"];

    // 🔥 FULL BLOCK
    _engine = createAgoraRtcEngine();

    await _engine?.initialize(
      RtcEngineContext(appId: appId),
    );

    await _engine?.setChannelProfile(
      ChannelProfileType.channelProfileCommunication,
    );

    await _engine?.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );

    _engine?.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!mounted) return;
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          _leaveCall(remote: true);
        },
      ),
    );

    if (widget.callType == "VOICE_CALL") {
      await _engine?.enableAudio();
      await _engine?.disableVideo();
    } else {
      await _engine?.enableVideo();
      await _engine?.startPreview();
    }

    await _engine?.joinChannel(
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
  }

  // ===============================
  // 🔥 TIMER
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

    if (_engine != null) {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _timer?.cancel();

    if (_engine != null) {
      _engine?.release();
      _engine = null;
    }

    super.dispose();
  }

  // ===============================
  // 🔥 UI
  // ===============================

  @override
  Widget build(BuildContext context) {

    // 🔥 WEB BLOCK
    if (kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text("Call Coming Soon 🚀"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              callStatus,
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
    );
  }
}
