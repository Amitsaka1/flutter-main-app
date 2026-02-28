import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
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

  Future<void> _joinRoom(String roomId) async {
    try {
      final token = await ApiClient.getToken();

      if (token == null) {
        throw Exception("User not logged in");
      }

      // ⚠ IMPORTANT
      // Backend join API में userId चाहिए
      // अगर backend JWT से निकालता है तो यहाँ userId मत भेजो
      // अभी assume कर रहे हैं कि userId token से decode नहीं हो रहा

      final userId = ""; // 🔥 NEXT STEP में real userId डालेंगे

      await RoomApi.joinRoom(userId, roomId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Joined room"),
        ),
      );

      // 🔥 NEXT STEP में RoomScreen navigate करेंगे

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
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
                      onTap: () =>
                          _joinRoom(room["id"]),
                    );
                  },
                ),
    );
  }
}
