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

class _AppLayoutState extends State<AppLayout>
    with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {

    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0f2027),
              Color(0xFF203a43),
              Color(0xFF2c5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [

            // 🔥 TOP NAVBAR
            _buildNavbar(),

            // 🔥 PAGE CONTENT WITH ANIMATION
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: widget.child,
              ),
            ),

            // 🔥 BOTTOM NAV
            _buildBottomNav(context, currentRoute),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _GradientLogo(),
          Icon(Icons.menu, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, String route) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      color: Colors.black.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [

          _NavItem(
            label: "Friends",
            icon: Icons.people,
            active: route.contains("dashboard"),
            onTap: () => context.go("/dashboard"),
          ),

          _ChatNavItem(
            unreadCount: widget.unreadCount,
            active: route.contains("chat"),
            onTap: () => context.go("/chat"),
          ),

          _NavItem(
            label: "Premium",
            icon: Icons.star,
            active: route.contains("premium"),
            highlightColor: const Color(0xFFFFD700),
            onTap: () => context.go("/premium"),
          ),
        ],
      ),
    );
  }
}

// -----------------------------
// 🔥 Gradient Logo Widget
// -----------------------------
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
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// -----------------------------
// 🔥 Normal Nav Item
// -----------------------------
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
        : Colors.white60;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

// -----------------------------
// 🔥 Chat Nav Item with Badge
// -----------------------------
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
        : Colors.white60;

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
              top: -4,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF00F5A0),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? "99+" : "$unreadCount",
                    style: const TextStyle(
                      fontSize: 12,
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
