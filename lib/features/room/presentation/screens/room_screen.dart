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
  bool _roomJoined = false; // 🔥 FIX: prevent duplicate join

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

    // 🔥 FIX: duplicate join रोकना
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

    /// SEAT MAP LISTENER
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

        if (!micStarted &&
            seat["userId"] == currentUserId &&
            (seat["role"] == "HOST" || seat["role"] == "SPEAKER")) {

          Future.delayed(const Duration(milliseconds: 500), () {
            voiceController.startSpeaking().catchError((_) {});
          });

          micStarted = true;
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

    /// JOIN ROOM
    await RoomApi.joinRoom(
      userId: userId,
      roomId: widget.roomId,
    );

    GlobalSocketManager.instance.joinRoom(widget.roomId);

      /// 🔥 FIX: FORCE SEAT MAP FETCH
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
          Navigator.of(context).maybePop(); // ✅ safe pop
        }
 
    });

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

    voiceController.webrtc.localStream?.getTracks().forEach((track) {
        track.stop();
    });
    
    voiceController.webrtc.localStream?.dispose();

    voiceController.reset();

    if (!mounted) return;

  }

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
    return true; // ✅ system handle करेगा pop
  }

  if (result == "EXIT") {
    await _leaveRoom();
    return true; // ✅ system pop करेगा
  }

  return false;
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
      seatIndex: seatIndex, // 🔥 IMPORTANT
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

          /// CHAT
          showChat: showChat,
          onChatToggle: toggleChat,

          /// GIFT
          showGift: showGift,
          onGiftToggle: toggleGift,
          ),
        ),
      );
    }

    // 🔥 ADD THIS HERE
    @override
    void dispose() {

      voiceController.webrtc.peerConnection?.close();

      voiceController.webrtc.localStream?.getTracks().forEach((track) {
        track.stop();
      });
  
      voiceController.webrtc.localStream?.dispose();

      chatController.dispose();

      super.dispose();

    }

  }
