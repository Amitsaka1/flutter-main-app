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

      if (data["type"] == "CALL_ENDED_LOW_BALANCE") {
        _leaveCall();
      }
      if (data["type"] == "CALL_ENDED") {
        _leaveCall();
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

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(
      RtcEngineContext(appId: appId),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          _leaveCall();
        },
      ),
    );

    if (widget.callType == "VOICE_CALL") {
      await _engine!.enableAudio();
      await _engine!.disableVideo();
    } else {
      await _engine!.enableVideo();
    }

    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
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

  Future<void> _leaveCall() async {
    _timer?.cancel();

    try {
      if (!_callConnected) {
        await ApiClient.post("/call/cancel", {
          "sessionId": widget.channelName
        });
      } else {
        await ApiClient.post("/call/end", {
          "sessionId": widget.channelName
        });
      }
    } catch (_) {}

    await _engine?.leaveChannel();
    await _engine?.release();

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _timer?.cancel();
    _engine?.release();
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
                  onPressed: _leaveCall,
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
