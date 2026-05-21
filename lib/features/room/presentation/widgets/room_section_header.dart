import 'package:flutter/material.dart';

class RoomSectionHeader extends StatelessWidget {
  final String title;

  const RoomSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Padding(
      padding: const EdgeInsets.all(12),

      child: Text(
        title,

        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // ================= UI END =================
  }
}
