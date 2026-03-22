import 'package:flutter/material.dart';
import '../../data/room_api.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/socket/global_socket_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/debug/app_debug.dart';
import '../../../../core/livekit/livekit_service.dart';

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

  final TextEditingController chatController = TextEditingController();

  List<String> messages = [];

  bool showChat = false;
  bool showGift = false;

  /// 🔥 LIVEKIT SERVICE
  final LiveKitService _livekit = LiveKitService();

  bool _livekitConnected = false;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  /// =========================
  /// 🔥 MIC PERMISSION
  /// =========================
  Future<void> requestMicPermission() async {
    final status = await Permission.microphone.request();

    if (!status.isGranted) {
      throw Exception("Microphone permission denied");
    }
  }

  /// =========================
  /// 🔥 INIT ROOM
  /// =========================
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
    GlobalSocketManager.instance.onSeatMapUpdate((data) async {
      if (!mounted) return;

      final seatData = data["seats"];
      if (seatData == null || seatData is! List) return;

      final updatedSeats = List<Map<String, dynamic>>.from(seatData);

      final currentUserId = UserSession.getUserId();

      bool hostFlag = false;
      bool amISpeaker = false;

      for (final seat in updatedSeats) {
        if (seat["userId"] == currentUserId) {
          if (seat["role"] == "HOST") hostFlag = true;
          if (seat["role"] == "HOST" ||
              seat["role"] == "SPEAKER") {
            amISpeaker = true;
          }
        }
      }

      /// 🔥 LIVEKIT CONNECT ONLY ONCE
      if (!_livekitConnected) {
        _livekitConnected = true;

        try {
          await _livekit.connect(
            userId: currentUserId!,
            roomId: widget.roomId,
          );

          /// 🔥 mic control based on role
          if (amISpeaker) {
            await _livekit.enableMic();
          } else {
            await _livekit.disableMic();
          }

        } catch (e) {
          AppDebug.log("LiveKit connect failed: $e");
        }
      } else {
        /// 🔥 role change → mic update
        if (amISpeaker) {
          await _livekit.enableMic();
        } else {
          await _livekit.disableMic();
        }
      }

      setState(() {
        seats = updatedSeats;
        isHost = hostFlag;
        loading = false;
      });
    });

    /// 🔥 JOIN ROOM (Backend)
    await RoomApi.joinRoom(
      userId: userId,
      roomId: widget.roomId,
    );

    /// 🔥 SOCKET JOIN
    GlobalSocketManager.instance.joinRoom(widget.roomId);

    /// 🔥 FORCE SEAT MAP
    GlobalSocketManager.instance.send({
      "type": "GET_SEAT_MAP",
      "roomId": widget.roomId,
    });

    /// 🔥 ROOM CLOSED
    GlobalSocketManager.instance.onRoomClosed(() async {
      if (!mounted) return;

      await _leaveRoom();
      Navigator.of(context).pop();
    });
  }

  /// =========================
  /// CHAT
  /// =========================
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

  /// =========================
  /// 🔥 LEAVE ROOM
  /// =========================
  Future<void> _leaveRoom() async {
    if (leavingRoom) return;
    leavingRoom = true;

    final userId = UserSession.getUserId();
    if (userId == null) return;

    try {
      /// 🔥 BACKEND LEAVE
      await RoomApi.leaveRoom(
        userId: userId,
        roomId: widget.roomId,
      );
    } catch (_) {}

    /// 🔥 SOCKET LEAVE
    GlobalSocketManager.instance.leaveRoom(widget.roomId);

    /// 🔥 LIVEKIT DISCONNECT
    await _livekit.disconnect();
  }

  /// =========================
  /// 🔥 BACK FIX
  /// =========================
  Future<bool> _onBackPressed() async {
    await _leaveRoom();
    return true;
  }

  /// =========================
  /// SEAT TAP
  /// =========================
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

  @override
  void dispose() {
    _livekit.disconnect(); // 🔥 safety
    chatController.dispose();
    super.dispose();
  }
}
