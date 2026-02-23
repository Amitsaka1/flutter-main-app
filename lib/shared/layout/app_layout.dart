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

    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.3,
            center: Alignment.topLeft,
            colors: [
              Color(0xFF0f2027),
              Color(0xFF1b2b34),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Column(
          children: [

            _buildNavbar(),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey(currentRoute),
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: widget.child,
                ),
              ),
            ),

            _buildBottomNav(context, currentRoute),
          ],
        ),
      ),
    );
  }

  // ================= TOP NAV =================

  Widget _buildNavbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _GradientLogo(),
          Icon(Icons.menu, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  // ================= BOTTOM NAV =================

  Widget _buildBottomNav(BuildContext context, String route) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF0a0a0a),
      boxShadow: [
        BoxShadow(
          color: Colors.cyanAccent.withOpacity(0.15),
          blurRadius: 25,
        )
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          active: route.startsWith("/rooms"),
          onTap: () {},
        ),

        _NavItem(
          label: "Premium",
          icon: Icons.workspace_premium_rounded,
          active: route.startsWith("/premium"),
          highlightColor: const Color(0xFFFFD700),
          onTap: () => context.go("/premium"),
        ),

        _NavItem(
          label: "Profile",
          icon: Icons.person_rounded,
          active: route.startsWith("/profile"),
          onTap: () {},
        ),
      ],
    ),
  );
  }

// ================= LOGO =================

class _GradientLogo extends StatelessWidget {
  const _GradientLogo();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00F5A0), Color(0xFFFF00C8)],
      ).createShader(bounds),
      child: const Text(
        "Naxorah",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ================= NAV ITEM =================

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

    final color = active
        ? highlightColor ?? const Color(0xFF00F5A0)
        : Colors.white54;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: active
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                  )
                ],
              )
            : null,
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

// ================= CHAT ITEM =================

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

    final color = active
        ? const Color(0xFF00F5A0)
        : Colors.white54;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Icon(Icons.chat_bubble, color: color),
              const SizedBox(height: 4),
              Text("Chat", style: TextStyle(color: color)),
            ],
          ),

          if (unreadCount > 0)
            Positioned(
              top: -6,
              right: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? "99+" : "$unreadCount",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
