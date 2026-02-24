import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/socket_manager.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final int unreadCount; // chat unread

  const AppLayout({
    super.key,
    required this.child,
    this.unreadCount = 0,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {

  int _notificationCount = 0;
  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();

    final socket = SocketManager.instance;

    if (socket != null) {
      _notificationSub = socket.notifications.listen((event) {
        setState(() {
          _notificationCount++;
        });
      });
    }
  }

  void clearNotifications() {
    setState(() {
      _notificationCount = 0;
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final currentRoute =
        GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Column(
        children: [

          // 🔔 TOP BAR WITH BELL
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: const Color(0xFF111111),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "Naxorah",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  GestureDetector(
                    onTap: clearNotifications,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [

                        const Icon(
                          Icons.notifications_none,
                          size: 26,
                        ),

                        if (_notificationCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints:
                                  const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  _notificationCount > 99
                                      ? "99+"
                                      : "$_notificationCount",
                                  style:
                                      const TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // ===== CONTENT =====
          Expanded(
            child: widget.child,
          ),

          // ===== BOTTOM NAV =====
          SafeArea(
            top: false,
            child: _buildBottomNav(context, currentRoute),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    String route,
  ) {
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
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [

          _NavItem(
            label: "Home",
            icon: Icons.home_rounded,
            active: route.startsWith("/dashboard"),
            onTap: () => context.go("/dashboard"),
          ),

          _ChatNavItem(
            unreadCount: widget.unreadCount,
            active: route.startsWith("/chat"),
            onTap: () => context.go("/chat"),
          ),

          _NavItem(
            label: "Rooms",
            icon: Icons.meeting_room_rounded,
            active: false,
            onTap: () {},
          ),

          _NavItem(
            label: "Premium",
            icon: Icons.workspace_premium_rounded,
            active: route.startsWith("/premium"),
            highlightColor:
                const Color(0xFFFFD700),
            onTap: () => context.go("/premium"),
          ),

          _NavItem(
            label: "Profile",
            icon: Icons.person_rounded,
            active: route == "/profile",
            onTap: () => context.go("/profile"),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color? highlightColor;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {

    final Color color = active
        ? highlightColor ??
            const Color(0xFF00F5A0)
        : Colors.white60;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [

          AnimatedContainer(
            duration:
                const Duration(milliseconds: 250),
            padding:
                const EdgeInsets.all(6),
            decoration: active
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withOpacity(0.5),
                        blurRadius: 14,
                      ),
                    ],
                  )
                : null,
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatNavItem extends StatelessWidget {
  final int unreadCount;
  final bool active;
  final VoidCallback onTap;

  const _ChatNavItem({
    required this.unreadCount,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final Color color = active
        ? const Color(0xFF00F5A0)
        : Colors.white60;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          Column(
            mainAxisSize:
                MainAxisSize.min,
            mainAxisAlignment:
                MainAxisAlignment.center,
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
                        horizontal: 6),
                height: 18,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF00F5A0),
                  borderRadius:
                      BorderRadius.circular(
                          20),
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
  }
}
