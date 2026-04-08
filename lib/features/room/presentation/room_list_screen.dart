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

// 🔥 FIX: split lists
List<dynamic> _myRooms = [];
List<dynamic> _liveRooms = [];

StreamSubscription? _socketSub;

@override
void initState() {
super.initState();
_loadRooms();
_listenRoomUpdates();
}

// =========================
// SOCKET LISTENER
// =========================
void _listenRoomUpdates() {
_socketSub = GlobalSocketManager.instance.messages.listen((event) {

  if (event["type"] == "ROOM_REMOVED") {
    final roomId = event["roomId"];

    if (!mounted) return;

    setState(() {
      _myRooms.removeWhere((room) => room["id"] == roomId);
      _liveRooms.removeWhere((room) => room["id"] == roomId);
    });
  }
});

}

// =========================
// LOAD ROOMS (MY + LIVE)
// =========================
Future<void> _loadRooms() async {
try {

  final userId = UserSession.getUserId();

  final myRooms = await RoomApi.getRooms(
    userId: userId,
    type: "MY",
  );

  final liveRooms = await RoomApi.getRooms();

  if (!mounted) return;

  setState(() {
    _myRooms = myRooms;
    _liveRooms = liveRooms;
    _loading = false;
  });

} catch (e) {
  if (!mounted) return;
  setState(() => _loading = false);
}

}

// =========================
// ENTER ROOM
// =========================
Future<void> _enterRoom(Map<String, dynamic> room) async {

final userId = UserSession.getUserId();
if (userId == null) return;

final roomId = room["id"];

try {

  // 🔥 activate if inactive
  if (room["status"] == "INACTIVE") {
    await RoomApi.activateRoom(
      userId: userId,
      roomId: roomId,
    );
  }

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
// CREATE ROOM
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
// CLEANUP
// =========================
@override
void dispose() {
_socketSub?.cancel();
super.dispose();
}

// =========================
// UI
// =========================
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
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _loadRooms,
          child: ListView(
            children: [

              // 🔥 MY ROOMS
              if (_myRooms.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "My Rooms",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._myRooms.map((room) => _roomTile(room)).toList(),
              ],

              // 🔥 LIVE ROOMS
              if (_liveRooms.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "🔥 Live Rooms",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._liveRooms.map((room) => _roomTile(room)).toList(),
              ],

              if (_myRooms.isEmpty && _liveRooms.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No rooms available"),
                )),

            ],
          ),
        ),
);

}

// =========================
// ROOM TILE
// =========================
Widget _roomTile(Map<String, dynamic> room) {

final isInactive = room["status"] == "INACTIVE";

return ListTile(
  title: Text(room["name"] ?? ""),
  subtitle: Text(
    isInactive
        ? "Inactive • Tap to Start"
        : "🔥 LIVE • ${room["currentMembers"] ?? 0} users",
  ),
  trailing: Icon(
    isInactive ? Icons.play_arrow : Icons.mic,
  ),
  onTap: () => _enterRoom(room),
);

}
}
