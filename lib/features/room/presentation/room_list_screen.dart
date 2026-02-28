import 'package:flutter/material.dart';
import '../data/room_api.dart';

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
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rooms"),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _rooms.isEmpty
              ? const Center(
                  child: Text("No active rooms"),
                )
              : ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];

                    return ListTile(
                      title: Text(room["name"] ?? ""),
                      subtitle: Text(
                        "Members: ${room["currentMembers"] ?? 0}",
                      ),
                      onTap: () {
                        // Next step में join करेंगे
                      },
                    );
                  },
                ),
    );
  }
}
