import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final int unreadCount;

  const AppLayout({
    super.key,
    required this.child,
    this.unreadCount = 0,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {

  @override
  Widget build(BuildContext context) {

    final currentRoute =
        GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Column(
        children: [

          Expanded(
            child: widget.child,
          ),

          _buildBottomNav(context, currentRoute),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
      BuildContext context,
      String route,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
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
            active: false,
            onTap: () {},
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          AnimatedContainer(
            duration:
                const Duration(milliseconds: 250),
            padding:
                const EdgeInsets.all(8),
            decoration: active
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withOpacity(0.5),
                        blurRadius: 15,
                      ),
                    ],
                  )
                : null,
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
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
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                "Chat",
                style:
                    TextStyle(color: color),
              ),
            ],
          ),

          if (unreadCount > 0)
            Positioned(
              top: -5,
              right: -10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 6),
                height: 20,
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
                      fontSize: 11,
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
