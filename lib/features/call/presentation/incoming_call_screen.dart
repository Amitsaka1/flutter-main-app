import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_project/core/network/api_client.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String sessionId;
  final String callerId;
  final String callType;

  const IncomingCallScreen({
    super.key,
    required this.sessionId,
    required this.callerId,
    required this.callType,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {

  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();

    // 🔥 Auto cancel after 30 seconds
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      _rejectCall();
    });
  }

  Future<void> _acceptCall() async {
    _timeoutTimer?.cancel();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: widget.sessionId,
          callType: widget.callType,
        ),
      ),
    );
  }

  Future<void> _rejectCall() async {
    _timeoutTimer?.cancel();

    try {
      await ApiClient.post("/call/end", {
        "sessionId": widget.sessionId
      });
    } catch (_) {}

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const SizedBox(height: 40),

            const Icon(
              Icons.account_circle,
              size: 120,
              color: Colors.white54,
            ),

            const SizedBox(height: 20),

            Text(
              "Incoming ${widget.callType == "VIDEO_CALL" ? "Video" : "Voice"} Call",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 80),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: _rejectCall,
                  child: const Icon(Icons.call_end),
                ),

                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: _acceptCall,
                  child: const Icon(Icons.call),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
