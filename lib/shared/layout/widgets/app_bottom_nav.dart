import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_item.dart';
import 'chat_nav_item.dart';

class AppBottomNav extends StatelessWidget {
  final String route;
  final int unreadCount;

  const AppBottomNav({
    super.key,
    required this.route,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {

    void safeGo(String path) {
      if (route != path) {
        context.pushReplacement(path);
      }
    }

    // ================= UI START =================

    return Container(
      padding: const EdgeInsets.only(
        top: 6,
        bottom: 6,
      ),

      decoration: const BoxDecoration(
        color: Color(0xFF111111),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,

        children: [

          NavItem(
            label: "Home",
            icon: Icons.home_rounded,
            active:
                route.startsWith("/dashboard"),
            onTap: () =>
                safeGo("/dashboard"),
          ),

          ChatNavItem(
            unreadCount: unreadCount,
            active:
                route.startsWith("/chat"),
            onTap: () =>
                safeGo("/chat"),
          ),

          NavItem(
            label: "Rooms",
            icon:
                Icons.meeting_room_rounded,
            active: false,
            onTap: () =>
                context.push("/coming-soon"),
          ),

          NavItem(
            label: "Premium",
            icon:
                Icons.workspace_premium_rounded,

            active:
                route.startsWith("/premium"),

            highlightColor:
                const Color(0xFFFFD700),

            onTap: () =>
                safeGo("/premium"),
          ),

          NavItem(
            label: "Profile",
            icon:
                Icons.person_rounded,

            active:
                route == "/profile",

            onTap: () =>
                safeGo("/profile"),
          ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
