import 'package:flutter/material.dart';

class RoomTile extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onTap;

  const RoomTile({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final isInactive =
        room["status"] == "INACTIVE";

    // ================= UI START =================

    return ListTile(
      title: Text(
        room["name"] ?? "",
      ),

      subtitle: Text(
        isInactive
            ? "Inactive • Tap to Start"
            : "🔥 LIVE • ${room["currentMembers"] ?? 0} users",
      ),

      trailing: Icon(
        isInactive
            ? Icons.play_arrow
            : Icons.mic,
      ),

      onTap: onTap,
    );

    // ================= UI END =================
  }
}
