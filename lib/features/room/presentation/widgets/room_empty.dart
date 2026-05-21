import 'package:flutter/material.dart';

class RoomEmpty extends StatelessWidget {
  const RoomEmpty({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),

        child: Text(
          "No rooms available",
        ),
      ),
    );

    // ================= UI END =================
  }
}
