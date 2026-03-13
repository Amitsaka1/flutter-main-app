import 'package:flutter/material.dart';
import '../../../core/session/user_session.dart';
import '../../../core/socket/global_socket_manager.dart';
import '../data/room_api.dart';
import '../../../controllers/voice_room_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;

  const RoomScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomScreen> createState() =>
      _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {

  List<dynamic> seats = [];
  bool loading = true;
  bool isHost = false;
  bool leavingRoom = false;

  final VoiceRoomController voiceController = VoiceRoomController();

  final TextEditingController chatController = TextEditingController();
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> requestMicPermission() async {

  var status = await Permission.microphone.request();

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
      const SnackBar(
        content: Text("Microphone permission required"),
      ),
    );

    Navigator.pop(context);

    return;

  }

  final userId = UserSession.getUserId();
    if (userId == null) return;

     // 🔥 Seat map listener
    GlobalSocketManager.instance
        .onSeatMapUpdate((data) {

      if (!mounted) return;

      final updatedSeats = data["seats"];
      final currentUserId =
          UserSession.getUserId();

      bool hostFlag = false;

      for (final seat in updatedSeats) {
        if (seat["userId"] == currentUserId &&
            seat["role"] == "HOST") {
          hostFlag = true;
          break;
        }
      }

      setState(() {
        seats = updatedSeats;
        isHost = hostFlag;
        loading = false;
      });
    });

    // 🔥 Room closed listener
    GlobalSocketManager.instance.onRoomClosed(() {
      if (!mounted) return;

      if (leavingRoom) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });

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

    print("🚀 WebRTC initialized");

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      if (loading) {
        setState(() {
          loading = false;
        });
      }
    });
  }
  

  // ================= SEAT TAP =================

  void _onSeatTap(Map<String, dynamic> seat) async {

    final userId = UserSession.getUserId();
    if (userId == null) return;

    // 🔹 EMPTY SEAT → Request speaker
    if (seat["userId"] == null) {

      try {
        await RoomApi.requestSpeaker(
          userId: userId,
          roomId: widget.roomId,
        );

        // mic start after seat map update
       Future.delayed(
         const Duration(milliseconds: 500),
         () async {
           await voiceController.startSpeaking();
         },
       );

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text("Seat request sent"),
          ),
        );

      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              e.toString()
                  .replaceAll("Exception: ", ""),
            ),
          ),
        );
      }

      return;
    }

    // 🔹 HOST → Demote speaker
    if (isHost &&
        seat["role"] == "SPEAKER" &&
        seat["userId"] != userId) {

      showModalBottomSheet(
        context: context,
        backgroundColor:
            const Color(0xFF111111),
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [

                  const Text(
                    "Speaker Controls",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ListTile(
                    leading:
                        const Icon(
                      Icons.remove_circle,
                      color: Colors.red,
                    ),
                    title: const Text(
                      "Remove from Speaker",
                      style: TextStyle(
                          color: Colors.red),
                    ),
                    onTap: () async {

                      Navigator.pop(context);

                      try {
                        await RoomApi
                            .demoteSpeaker(
                          hostId: userId,
                          roomId:
                              widget.roomId,
                          targetUserId:
                              seat["userId"],
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger
                                .of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString()
                                  .replaceAll(
                                      "Exception: ",
                                      ""),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );

      return;
    }

    // 🔹 Otherwise
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text("Seat already occupied"),
      ),
    );
  }

  // ================= LEAVE ROOM =================

  Future<void> _leaveRoom() async {

    leavingRoom = true;

    final userId =
        UserSession.getUserId();
    if (userId == null) return;

    await RoomApi.leaveRoom(
      userId: userId,
      roomId: widget.roomId,
    );

    GlobalSocketManager.instance
        .leaveRoom(widget.roomId);

    if (!mounted) return;
    Navigator.pop(context);
  }

  void sendMessage() {

  if (chatController.text.trim().isEmpty) return;

  setState(() {
    messages.add(chatController.text);
  });

  chatController.clear();

  }

  @override
  void dispose() {
    try {
      GlobalSocketManager.instance.leaveRoom(widget.roomId);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [

                // BACKGROUND
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0F0F1A),
                        Color(0xFF1B1B2F),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // CHAT PANEL
                Positioned(
                  left: 0,
                  top: 120,
                  bottom: 120,
                  width: 250,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [

                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "Chat",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
  
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  messages[index],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );

                            },
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [

                              Expanded(
                                child: TextField(
                                  controller: chatController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: "Type message...",
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.send, color: Colors.blue),
                                onPressed: sendMessage,
                              )

                            ],
                          ),
                        )

                      ],
                    ),
                  ),
                ),

              Column(
                children: [

                  const SizedBox(height: 50),

                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const Text(
                        "Voice Party",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "LIVE ${seats.length}/12",
                          style: const TextStyle(color: Colors.white),
                        ),
                      )

                    ],
                  ),

                  const SizedBox(height: 20),

                  // SEATS GRID
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {

                        int columns = 3;

                        if (constraints.maxWidth > 900) {
                          columns = 5;
                        } else if (constraints.maxWidth > 600) {
                          columns = 4;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: seats.length,
                          itemBuilder: (context, index) {

                            final seat = seats[index];
                            final occupied = seat["userId"] != null;

                            return GestureDetector(
                              onTap: () => _onSeatTap(seat),
                              child: Column(
                                children: [

                                  Stack(
                                    alignment: Alignment.center,
                                    children: [

                                      // SPEAKING GLOW
                                      if (occupied)
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.green
                                                    .withOpacity(0.6),
                                                blurRadius: 15,
                                                spreadRadius: 3,
                                              )
                                            ],
                                          ),
                                        ),

                                      CircleAvatar(
                                        radius: 35,
                                        backgroundColor:
                                            Colors.grey.shade800,
                                        child: occupied
                                            ? const Icon(Icons.person,
                                                color: Colors.white)
                                            : const Icon(Icons.add,
                                                color: Colors.white54),
                                      ),

                                      // MIC ICON
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.black,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.mic,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    occupied
                                        ? seat["userId"]
                                        : "Empty",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  )

                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),

              // BOTTOM CONTROLS
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [

                        Column(
                          children: [
                            Icon(Icons.card_giftcard,
                                color: Colors.amber),
                            SizedBox(height: 4),
                            Text("Gift",
                                style: TextStyle(color: Colors.white))
                          ],
                        ),

                        SizedBox(width: 40),

                        Column(
                          children: [
                            Icon(Icons.mic, color: Colors.white),
                            SizedBox(height: 4),
                            Text("Mic",
                                style: TextStyle(color: Colors.white))
                          ],
                        ),

                        SizedBox(width: 40),

                        Column(
                          children: [
                            Icon(Icons.image, color: Colors.white),
                            SizedBox(height: 4),
                            Text("Frame",
                                style: TextStyle(color: Colors.white))
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // EXIT BUTTON
              Positioned(
                top: 40,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _leaveRoom,
                ),
              ),

            ],
          ),
  );
}
