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

            // 🔥 PAGE CONTENT
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Container(
                  key: ValueKey(currentRoute), // ✅ VERY IMPORTANT FIX
                  width: double.infinity,
                  height: double.infinity,
                  child: widget.child,
                ),
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
      color: Colors.black.withOpacity(0.85),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [

          _NavItem(
            label: "Friends",
            icon: Icons.people,
            active: route.startsWith("/dashboard"),
            onTap: () => context.go("/dashboard"),
          ),

          _ChatNavItem(
            unreadCount: widget.unreadCount,
            active: route.startsWith("/chat"),
            onTap: () => context.go("/chat"),
          ),

          _NavItem(
            label: "Premium",
            icon: Icons.star,
            active: route.startsWith("/premium"),
            highlightColor: const Color(0xFFFFD700),
            onTap: () => context.go("/premium"),
          ),
        ],
      ),
    );
  }
}
