import 'package:flutter/material.dart';

class ChatCard extends StatelessWidget {
  final dynamic chat;
  final VoidCallback onTap;

  const ChatCard({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final unread =
        chat["unreadCount"] ?? 0;

    // ================= UI START =================

    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius:
              BorderRadius.circular(20),
        ),

        child: Row(
          children: [

            CircleAvatar(
              child: Text(
                chat["user"]["phone"]
                    .toString()
                    .substring(
                      chat["user"]["phone"]
                              .length -
                          2,
                    ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    chat["user"]["phone"],
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    chat["lastMessage"] ?? "",
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (unread > 0)
              CircleAvatar(
                radius: 12,
                backgroundColor:
                    Colors.green,

                child: Text(
                  "$unread",

                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // ================= UI END =================
  }
}
