import 'package:flutter/material.dart';

class ChatNavItem extends StatelessWidget {
  final int unreadCount;
  final bool active;
  final VoidCallback onTap;

  const ChatNavItem({
    super.key,
    required this.unreadCount,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final Color color = active
        ? const Color(0xFF00F5A0)
        : Colors.white60;

    // ================= UI START =================

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,

      child: Stack(
        clipBehavior: Clip.none,

        children: [

          Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [

              Icon(
                Icons.chat_bubble,
                color: color,
                size: 24,
              ),

              const SizedBox(height: 4),

              Text(
                "Chat",
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -8,

              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 6,
                ),

                height: 18,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFF00F5A0),

                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Center(
                  child: Text(
                    unreadCount > 99
                        ? "99+"
                        : "$unreadCount",

                    style:
                        const TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
