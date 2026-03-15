import 'package:flutter/material.dart';
import '../../data/room_api.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/socket/global_socket_manager.dart';
import '../../../../controllers/voice_room_controller.dart';
import 'package:permission_handler/permission_handler.dart';

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

  final VoiceRoomController voiceController = VoiceRoomController();

  final TextEditingController chatController = TextEditingController();

  List<String> messages = [];

  bool micStarted = false;

  /// CHAT STATE
  bool showChat = false;

  /// GIFT STATE
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

    /// SEAT MAP LISTENER
    GlobalSocketManager.instance.onSeatMapUpdate((data) {

      if (!mounted) return;

      final seatData = data["seats"];

      if (seatData == null || seatData is! List) return;

      final updatedSeats = List<Map<String, dynamic>>.from(seatData);

      final currentUserId = UserSession.getUserId();

      bool hostFlag = false;

      for (final seat in updatedSeats) {

        if (seat["userId"] == currentUserId && seat["role"] == "HOST") {
          hostFlag = true;
        }

        if (!micStarted &&
            seat["userId"] == currentUserId &&
            (seat["role"] == "HOST" || seat["role"] == "SPEAKER")) {

          Future.delayed(const Duration(milliseconds: 500), () {
            voiceController.startSpeaking().catchError((_) {});
          });

          micStarted = true;
        }

      }

      setState(() {
        seats = updatedSeats;
        isHost = hostFlag;
        loading = false;
      });

    });

    /// JOIN ROOM
    await RoomApi.joinRoom(
      userId: userId,
      roomId: widget.roomId,
    );

    GlobalSocketManager.instance.joinRoom(widget.roomId);

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

  /// CHAT TOGGLE
  void toggleChat() {

    setState(() {

      showChat = !showChat;

      /// close gift if open
      if (showChat) {
        showGift = false;
      }

    });

  }

  /// GIFT TOGGLE
  void toggleGift() {

    setState(() {

      showGift = !showGift;

      /// close chat if open
      if (showGift) {
        showChat = false;
      }

    });

  }

  /// LEAVE ROOM
  Future<void> _leaveRoom() async {

    leavingRoom = true;

    final userId = UserSession.getUserId();

    if (userId == null) return;

    await RoomApi.leaveRoom(
      userId: userId,
      roomId: widget.roomId,
    );

    GlobalSocketManager.instance.leaveRoom(widget.roomId);

      // 🔥 STOP WEBRTC CONNECTION
    voiceController.webrtc.peerConnection?.close();
    voiceController.webrtc.localStream?.dispose();

    if (!mounted) return;

    Navigator.pop(context);

  }

  /// SEAT TAP
  void _onSeatTap(Map<String, dynamic> seat) async {

  final userId = UserSession.getUserId();
  if (userId == null) return;

  final seatUserId = seat["userId"];
  final seatIndex = seat["seatIndex"];

  // 🔒 host seat lock
  if (seatIndex == 1 && !isHost) {
    return;
  }

  // ❌ seat occupied
  if (seatUserId != null) {
    return;
  }

  try {

    // 🔥 Request speaker / shift seat
    await RoomApi.requestSpeaker(
      userId: userId,
      roomId: widget.roomId,
      seatIndex: seat["seatIndex"],
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

    return Scaffold(
      body: RoomUI(
        seats: seats,
        messages: messages,
        controller: chatController,
        onSend: sendMessage,
        onSeatTap: _onSeatTap,

        /// CHAT
        showChat: showChat,
        onChatToggle: toggleChat,

        /// GIFT
        showGift: showGift,
        onGiftToggle: toggleGift,
      ),
    );

  }

}
