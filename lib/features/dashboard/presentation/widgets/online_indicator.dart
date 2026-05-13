import 'package:flutter/material.dart';

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return CircleAvatar(
      radius: 6,
      backgroundColor: Colors.green,
    );

    // ===================== UI END =======================
  }
}
