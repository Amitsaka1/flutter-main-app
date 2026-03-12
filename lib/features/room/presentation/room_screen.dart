import 'package:flutter/material.dart';
import '../../../core/session/user_session.dart';
import '../../../core/socket/global_socket_manager.dart';
import '../data/room_api.dart';
import '../../../controllers/voice_room_controller.dart';

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

  final VoiceRoomController voiceController = VoiceRoomController();

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> _initRoom() async {

    final userId = UserSession.getUserId();
    if (userId == null) return;

    GlobalSocketManager.instance
        .joinRoom(widget.roomId);

    await voiceController.joinRoom(
      widget.roomId,
      userId!,
      GlobalSocketManager.instance.wsUrl,
    );

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
    GlobalSocketManager.instance
        .onRoomClosed(() {
      if (!mounted) return;
      Navigator.pop(context);
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
        Future.delayed(const Duration(milliseconds: 500), async {

          await voiceController.startSpeaking();

          print("🎤 Microphone started");

         });

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

  @override
  void dispose() {
    GlobalSocketManager.instance
        .leaveRoom(widget.roomId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Room"),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.exit_to_app),
            onPressed: _leaveRoom,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : GridView.builder(
              padding:
                  const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: seats.length,
              itemBuilder:
                  (context, index) {

                final seat =
                    seats[index];

                final occupied =
                    seat["userId"] != null;

                return GestureDetector(
                  onTap: () =>
                      _onSeatTap(seat),
                  child: Container(
                    decoration:
                        BoxDecoration(
                      color: occupied
                          ? const Color(
                              0xFF00F5A0)
                          : Colors
                              .grey[800],
                      borderRadius:
                          BorderRadius
                              .circular(12),
                    ),
                    child: Center(
                      child: Text(
                        occupied
                            ? seat["userId"]
                            : "Empty",
                        style:
                            const TextStyle(
                                fontSize:
                                    12),
                        textAlign:
                            TextAlign
                                .center,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
