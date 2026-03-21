import 'package:flutter/material.dart';
import '../../data/room_api.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/socket/global_socket_manager.dart';
import '../../../../controllers/voice_room_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/debug/app_debug.dart'; // 🔥 FIX: missing import

import '../widgets/room_ui.dart';

class RoomScreen extends StatefulWidget {

  final String roomId;

  const RoomScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();

}

class _RoomScreenState extends State<RoomScreen> {

  List<Map<String, dynamic>> seats = [];

  bool loading = true;
  bool isHost = false;
  bool leavingRoom = false;
  bool _roomJoined = false;

  final VoiceRoomController voiceController = VoiceRoomController();

  final TextEditingController chatController = TextEditingController();

  List<String> messages = [];

  bool micStarted = false;

  bool showChat = false;
  bool showGift = false;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> requestMicPermission() async {
    final status = await Permission.microphone.request();

    if (!status.isGranted) {
      throw Exception("Microphone permission denied");
    }
  }

  Future<void> _initRoom() async {

    if (_roomJoined) return;
    _roomJoined = true;

    try {
      await requestMicPermission();
    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission required")),
      );

      Navigator.pop(context);
      return;
    }

    final userId = UserSession.getUserId();
    if (userId == null) return;

    /// 🔥 SEAT MAP LISTENER
    GlobalSocketManager.instance.onSeatMapUpdate((data) {

      if (!mounted) return;

      final seatData = data["seats"];
      if (seatData == null || seatData is! List) return;

      final updatedSeats = List<Map<String, dynamic>>.from(seatData);
      final currentUserId = UserSession.getUserId();

      bool hostFlag = false;
      bool userOnSeat = false;

      for (final seat in updatedSeats) {

        if (seat["userId"] == currentUserId) {
          userOnSeat = true;
        }

        if (seat["userId"] == currentUserId && seat["role"] == "HOST") {
          hostFlag = true;
        }

        /// 🔥 MIC START FIX (transport wait)
        if (!micStarted &&
            seat["userId"] == currentUserId &&
            (seat["role"] == "HOST" || seat["role"] == "SPEAKER")) {

          Future.delayed(const Duration(seconds: 2), () async {

            int retry = 0;

            while (voiceController.transportId == null && retry < 10) {
              await Future.delayed(const Duration(milliseconds: 300));
              retry++;
            }

            if (voiceController.transportId != null) {
              AppDebug.log("[VOICE] Transport ready → starting mic");
              await voiceController.startSpeaking().catchError((_) {});
              micStarted = true;
            } else {
              AppDebug.log("[VOICE] ERROR: transport not ready after wait");
            }

          });
        }
      }

      /// 🔥 USER LEFT SEAT → MIC OFF
      if (!userOnSeat && micStarted) {

        voiceController.webrtc.localStream?.getTracks().forEach((track) {
          track.stop();
        });

        voiceController.webrtc.localStream?.dispose();

        micStarted = false;
      }

      setState(() {
        seats = updatedSeats;
        isHost = hostFlag;
        loading = false;
      });

    });

    /// 🔥 JOIN ROOM
    await RoomApi.joinRoom(
      userId: userId,
      roomId: widget.roomId,
    );

    GlobalSocketManager.instance.joinRoom(widget.roomId);

    /// 🔥 FORCE SEAT MAP FETCH
    GlobalSocketManager.instance.send({
      "type": "GET_SEAT_MAP",
      "roomId": widget.roomId,
    });

    /// 🔥 ROOM CLOSED LISTENER
    GlobalSocketManager.instance.onRoomClosed(() {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room closed")),
      );

      if (mounted) {
        Navigator.of(context).maybePop(); // ✅ safe
      }

    });

    /// 🔥 VOICE JOIN
    await voiceController.joinRoom(
      widget.roomId,
      userId,
      GlobalSocketManager.instance.wsUrl,
    );

  }

  /// CHAT SEND
  void sendMessage() {
    final text = chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(text);
    });

    chatController.clear();
  }

  void toggleChat() {
    setState(() {
      showChat = !showChat;
      if (showChat) showGift = false;
    });
  }

  void toggleGift() {
    setState(() {
      showGift = !showGift;
      if (showGift) showChat = false;
    });
  }

  /// 🔥 LEAVE ROOM
  Future<void> _leaveRoom() async {

    leavingRoom = true;

    final userId = UserSession.getUserId();
    if (userId == null) return;

    await RoomApi.leaveRoom(
      userId: userId,
      roomId: widget.roomId,
    );

    GlobalSocketManager.instance.leaveRoom(widget.roomId);

    // 🔥 ADD THIS (VERY IMPORTANT)
    voiceController.webrtc.socket?.sink.close();
    voiceController.webrtc.socket = null;

    voiceController.webrtc.peerConnection?.close();

    voiceController.webrtc.localStream?.getTracks().forEach((track) {
      track.stop();
    });

    voiceController.webrtc.localStream?.dispose();

    voiceController.reset(); // 🔥 FIX

  }

  /// 🔥 BACK PRESS
  Future<bool> _onBackPressed() async {

    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Leave Room"),
          content: const Text("Keep room running or exit completely?"),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context, "KEEP");
              },
              child: const Text("Keep"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, "EXIT");
              },
              child: const Text("Exit"),
            ),

          ],
        );
      },
    );

    if (result == "KEEP") {
      Navigator.of(context).pop(); // 🔥 FIX
      return false;
    }

    if (result == "EXIT") {
      await _leaveRoom();
      return true;
    }

    return false;
  }

  /// SEAT TAP
  void _onSeatTap(Map<String, dynamic> seat) async {

    final userId = UserSession.getUserId();
    if (userId == null) return;

    final seatUserId = seat["userId"];
    final seatIndex = seat["seatIndex"];

    if (seatIndex == 1 && !isHost) return;
    if (seatUserId != null) return;

    try {

      await RoomApi.requestSpeaker(
        userId: userId,
        roomId: widget.roomId,
        seatIndex: seatIndex,
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: RoomUI(
          seats: seats,
          messages: messages,
          controller: chatController,
          onSend: sendMessage,
          onSeatTap: _onSeatTap,
          showChat: showChat,
          onChatToggle: toggleChat,
          showGift: showGift,
          onGiftToggle: toggleGift,
        ),
      ),
    );
  }

  /// 🔥 DISPOSE FIXED POSITION
  @override
  void dispose() {

    voiceController.webrtc.peerConnection?.close();

    voiceController.webrtc.localStream?.getTracks().forEach((track) {
      track.stop();
    });

    voiceController.webrtc.localStream?.dispose();

    voiceController.reset(); // 🔥 IMPORTANT

    chatController.dispose();

    super.dispose();
  }

}
