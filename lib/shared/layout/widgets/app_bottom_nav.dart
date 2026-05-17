import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_item.dart';
import 'chat_nav_item.dart';

// ─────────────────────────────────────────────
//  APP BOTTOM NAV  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class AppBottomNav extends StatefulWidget {
  final String route;
  final int    unreadCount;

  const AppBottomNav({
    super.key,
    required this.route,
    required this.unreadCount,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg      = Color(0xFF0E0E18);
  static const _goldA   = Color(0xFFD4A843);
  static const _goldB   = Color(0xFFE8C86A);
  static const _border  = Color(0xFF1E1E2E);
  static const _surface = Color(0xFF13131F);

  // ── Indicator animation ──────────────────────
  late AnimationController _indicatorCtrl;
  late Animation<double>   _indicatorScale;

  String _prevRoute = '';

  @override
  void initState() {
    super.initState();

    _prevRoute = widget.route;

    _indicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _indicatorScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorCtrl,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(AppBottomNav old) {
    super.didUpdateWidget(old);
    if (old.route != widget.route) {
      _prevRoute = old.route;
      _indicatorCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _indicatorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // ===================== LOGIC START =====================

    void safeGo(String path) {
      if (widget.route != path) {
        context.pushReplacement(path);
      }
    }

    // ===================== LOGIC END =======================

    // ===================== UI START =====================

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical:   10,
      ),
      color: Colors.transparent,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [

          // ── Home ───────────────────────────────
          _NavWrapper(
            active:  widget.route.startsWith("/dashboard"),
            indicatorScale: _indicatorScale,
            child: NavItem(
              label:  "Home",
              icon:   Icons.home_rounded,
              active: widget.route.startsWith("/dashboard"),
              onTap:  () => safeGo("/dashboard"),
            ),
          ),

          // ── Chat ───────────────────────────────
          _NavWrapper(
            active:  widget.route.startsWith("/chat"),
            indicatorScale: _indicatorScale,
            child: ChatNavItem(
              unreadCount: widget.unreadCount,
              active:      widget.route.startsWith("/chat"),
              onTap:       () => safeGo("/chat"),
            ),
          ),

          // ── Rooms ──────────────────────────────
          _NavWrapper(
            active:  false,
            indicatorScale: _indicatorScale,
            child: NavItem(
              label:  "Rooms",
              icon:   Icons.meeting_room_rounded,
              active: false,
              onTap:  () => context.push("/coming-soon"),
            ),
          ),

          // ── Premium ────────────────────────────
          _NavWrapper(
            active:  widget.route.startsWith("/premium"),
            indicatorScale: _indicatorScale,
            isPremium: true,
            child: NavItem(
              label:          "Premium",
              icon:           Icons.workspace_premium_rounded,
              active:         widget.route.startsWith("/premium"),
              highlightColor: const Color(0xFFFFD700),
              onTap:          () => safeGo("/premium"),
            ),
          ),

          // ── Profile ────────────────────────────
          _NavWrapper(
            active:  widget.route == "/profile",
            indicatorScale: _indicatorScale,
            child: NavItem(
              label:  "Profile",
              icon:   Icons.person_rounded,
              active: widget.route == "/profile",
              onTap:  () => safeGo("/profile"),
            ),
          ),

        ],
      ),
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Nav Wrapper — active indicator + press scale
// ─────────────────────────────────────────────

class _NavWrapper extends StatefulWidget {
  final Widget             child;
  final bool               active;
  final bool               isPremium;
  final Animation<double>  indicatorScale;

  const _NavWrapper({
    required this.child,
    required this.active,
    required this.indicatorScale,
    this.isPremium = false,
  });

  @override
  State<_NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<_NavWrapper> {

  static const _goldA  = Color(0xFFD4A843);
  static const _goldB  = Color(0xFFE8C86A);
  static const _accent = Color(0xFF6C63FF);

  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _isPressed = true),
      onTapUp:     (_) => setState(() => _isPressed = false),
      onTapCancel: ()  => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,

      child: AnimatedScale(
        scale:    _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,

        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Active indicator dot ─────────────
              AnimatedBuilder(
                animation: widget.indicatorScale,
                builder: (_, __) {
                  return Transform.scale(
                    scale: widget.active
                        ? widget.indicatorScale.value
                        : 0.0,
                    child: Container(
                      width:  20,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: widget.isPremium
                              ? [
                                  const Color(0xFFE8C86A),
                                  const Color(0xFFFFD700),
                                ]
                              : [_goldA, _goldB],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isPremium
                                    ? const Color(0xFFFFD700)
                                    : _goldA)
                                .withOpacity(0.7),
                            blurRadius:   8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── Nav item ─────────────────────────
              widget.child,

            ],
          ),
        ),
      ),
    );
  }
}
