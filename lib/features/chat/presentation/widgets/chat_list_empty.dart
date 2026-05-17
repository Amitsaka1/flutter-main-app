import 'package:flutter/material.dart';

class ChatListEmpty extends StatelessWidget {
  final bool loading;

  const ChatListEmpty({
    super.key,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return const Center(
      child: Text(
        "No chats yet",
      ),
    );

    // ================= UI END =================
  }
}
