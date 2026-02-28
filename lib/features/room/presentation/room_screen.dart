import 'package:flutter/material.dart';
import '../../../core/session/user_session.dart';
import '../../../core/socket/global_socket_manager.dart';
import '../data/room_api.dart';

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

class _RoomScreenState
    extends State<RoomScreen> {

  List<dynamic> seats = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> _initRoom() async {

    final userId =
        UserSession.getUserId();

    if (userId == null) return;

    // 🔥 Join socket room
    GlobalSocketManager.instance
        .joinRoom(widget.roomId);

    // 🔥 Listen seat updates
    GlobalSocketManager.instance
        .onSeatMapUpdate((data) {

      if (!mounted) return;

      setState(() {
        seats = data["seats"];
        loading = false;
      });
    });

    // 🔥 Listen room closed
    GlobalSocketManager.instance
        .onRoomClosed(() {

      if (!mounted) return;

      Navigator.pop(context);
    });
  }

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
            icon: const Icon(Icons.exit_to_app),
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
              itemBuilder: (context, index) {

                final seat = seats[index];

                return Container(
                  decoration: BoxDecoration(
                    color: seat["userId"] == null
                        ? Colors.grey[800]
                        : const Color(0xFF00F5A0),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      seat["userId"] ?? "Empty",
                      style: const TextStyle(
                          fontSize: 12),
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
