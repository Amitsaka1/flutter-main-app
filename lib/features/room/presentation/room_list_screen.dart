import 'package:flutter/material.dart';
import '../../../core/session/user_session.dart';
import '../data/room_api.dart';
import 'package:go_router/go_router.dart';
import '../../../core/socket/global_socket_manager.dart';
import 'dart:async';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() =>
      _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {

  bool _loading = true;
  List<dynamic> _rooms = [];

  StreamSubscription? _socketSub; // 🔥 FIX

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _listenRoomUpdates();
  }

  // =========================
  // 🔥 SOCKET LISTENER (SAFE)
  // =========================
  void _listenRoomUpdates() {
    _socketSub = GlobalSocketManager.instance.messages.listen((event) {

      if (event["type"] == "ROOM_REMOVED") {
        final roomId = event["roomId"];

        if (!mounted) return;

        setState(() {
          _rooms.removeWhere((room) => room["id"] == roomId);
        });
      }
    });
  }

  // =========================
  // 🔥 LOAD MY ROOMS
  // =========================
  Future<void> _loadRooms() async {
    try {

      final userId = UserSession.getUserId();

      final rooms = await RoomApi.getRooms(
        userId: userId,
        type: "MY",
      );

      if (!mounted) return;

      setState(() {
        _rooms = rooms;
        _loading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // =========================
  // 🔥 ENTER ROOM (FINAL FIX)
  // =========================
  Future<void> _enterRoom(Map<String, dynamic> room) async {

    final userId = UserSession.getUserId();
    if (userId == null) return;

    final roomId = room["id"];

    try {

      // 🔥 अगर inactive है → activate (auto join backend)
      if (room["status"] == "INACTIVE") {
        await RoomApi.activateRoom(
          userId: userId,
          roomId: roomId,
        );
      }

      // ❌ JOIN REMOVED (important)
      // अब backend खुद join कर रहा है

      if (!mounted) return;

      context.push(
        "/room",
        extra: {
          "roomId": roomId,
        },
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

  // =========================
  // 🔥 CREATE ROOM
  // =========================
  void _openCreateRoomDialog() {

    final TextEditingController nameController =
        TextEditingController();

    final TextEditingController descController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Start Room"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "Room name",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  hintText: "Description (optional)",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {

                final userId = UserSession.getUserId();
                if (userId == null) return;

                try {

                  final roomId = await RoomApi.createRoom(
                    userId: userId,
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                  );

                  // 🔥 activate = auto join
                  await RoomApi.activateRoom(
                    userId: userId,
                    roomId: roomId,
                  );

                  if (!mounted) return;

                  Navigator.pop(context);

                  context.push(
                    "/room",
                    extra: {
                      "roomId": roomId,
                    },
                  );

                } catch (e) {

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll("Exception: ", ""),
                      ),
                    ),
                  );
                }
              },
              child: const Text("Start"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // 🔥 CLEANUP (IMPORTANT)
  // =========================
  @override
  void dispose() {
    _socketSub?.cancel(); // 🔥 FIX memory leak
    super.dispose();
  }

  // =========================
  // 🔥 UI
  // =========================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Room"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openCreateRoomDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? const Center(child: Text("No room found"))
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView.builder(
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {

                      final room = _rooms[index];

                      final isInactive =
                          room["status"] == "INACTIVE";

                      return ListTile(
                        title: Text(room["name"] ?? ""),
                        subtitle: Text(
                          isInactive
                              ? "Inactive • Tap to Start"
                              : "Live • Members: ${room["currentMembers"] ?? 0}",
                        ),
                        trailing: Icon(
                          isInactive
                              ? Icons.play_arrow
                              : Icons.mic,
                        ),
                        onTap: () => _enterRoom(room),
                      );
                    },
                  ),
                ),
    );
  }
}
