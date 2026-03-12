import 'package:flutter/material.dart';
import '../../../core/session/user_session.dart';
import '../data/room_api.dart';
import 'package:go_router/go_router.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() =>
      _RoomListScreenState();
}

class _RoomListScreenState
    extends State<RoomListScreen> {

  bool _loading = true;
  List<dynamic> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await RoomApi.getRooms();

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

  Future<void> _joinRoom(String roomId) async {

    final userId = UserSession.getUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not logged in"),
        ),
      );
      return;
    }

    try {

      await RoomApi.joinRoom(
        userId: userId,
        roomId: roomId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Joined room successfully"),
        ),
      );

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

  void _openCreateRoomDialog() {

    final TextEditingController nameController =
        TextEditingController();

    final TextEditingController descController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Room"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(
                  hintText: "Room name",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration:
                    const InputDecoration(
                  hintText: "Description (optional)",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {

                final userId =
                    UserSession.getUserId();

                if (userId == null) return;

                try {

                  // 🔥 Create room
                  final roomId = await RoomApi.createRoom(
                    userId: userId,
                    name: nameController.text.trim(),
                    description:
                        descController.text.trim(),
                  );

                  // 🔥 Activate room
                  await RoomApi.activateRoom(
                    userId: userId,
                    roomId: roomId,
                  );

                  if (!mounted) return;

                  Navigator.pop(context);

                  // 🔥 Host direct room enter
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
                        e.toString().replaceAll(
                            "Exception: ", ""),
                      ),
                    ),
                  );
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rooms"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openCreateRoomDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _rooms.isEmpty
              ? const Center(
                  child: Text("No active rooms"),
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView.builder(
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {

                      final room = _rooms[index];

                      return ListTile(
                        title: Text(room["name"] ?? ""),
                        subtitle: Text(
                          "Members: ${room["currentMembers"] ?? 0}",
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                        onTap: () =>
                            _joinRoom(room["id"]),
                      );
                    },
                  ),
                ),
    );
  }
}
