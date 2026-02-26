import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:app_project/core/utils/permission_helper.dart';
import 'package:app_project/core/network/api_client.dart';
import 'package:app_project/core/socket/global_socket_manager.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String callType; // 🔥 NEW

  const CallScreen({
    super.key,
    required this.channelName,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {

  RtcEngine? _engine;
  int? _remoteUid;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _initCall();

    // 🔥 Listen for low balance auto end
    _socketSub =
        GlobalSocketManager.instance.messages.listen((data) {

      if (data["type"] == "CALL_ENDED_LOW_BALANCE") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Call ended: Low balance")),
          );
          _leaveCall();
        }
      }
    });
  }

  Future<void> _initCall() async {

    final granted = await PermissionHelper.requestCallPermissions();
    if (!granted) return;

    final response = await ApiClient.post("/call/token", {
      "channelName": widget.channelName
    });

    final token = response["token"];
    final appId = response["appId"];

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUid = null);
        },
      ),
    );

    // ===============================
    // 🔥 SEPARATE VOICE / VIDEO LOGIC
    // ===============================

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

  Future<void> _leaveCall() async {

    try {
      await ApiClient.post("/call/end", {
        "sessionId": widget.channelName
      });
    } catch (_) {}

    await _engine?.leaveChannel();
    await _engine?.release();

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // 🔥 Only show video view if VIDEO_CALL
          if (widget.callType == "VIDEO_CALL" &&
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

          // 🔥 Voice Call UI
          if (widget.callType == "VOICE_CALL")
            const Center(
              child: Icon(
                Icons.call,
                color: Colors.white,
                size: 100,
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: _leaveCall,
                child: const Icon(Icons.call_end),
              ),
            ),
          )
        ],
      ),
    );
  }
}
