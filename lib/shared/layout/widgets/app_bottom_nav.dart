import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_item.dart';
import 'chat_nav_item.dart';

// ─────────────────────────────────────────────
//  APP BOTTOM NAV  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

// modify: Fix #20 — route (String) → navigationShell (StatefulNavigationShell)
//
// Pehle: context.pushReplacement(path) — har tap pe poora screen
//        dispose+recreate hota tha, koi state preserve nahi hoti thi
// Ab: navigationShell.goBranch(index) — IndexedStack mein sirf
//     visibility switch hoti hai, screen zinda rehta hai
//
// Branch order — app.dart ke StatefulShellRoute branches se EXACTLY match:
// 0 = Dashboard, 1 = Chat, 2 = Voice World, 3 = Premium, 4 = Profile

class AppBottomNav extends StatefulWidget {
  final StatefulNavigationShell navigationShell; // new: Fix #20
  final int                     unreadCount;

  const AppBottomNav({
    super.key,
    required this.navigationShell, // new: Fix #20
    required this.unreadCount,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {

  static const _bg      = Color(0xFF0E0E18);
  static const _goldA   = Color(0xFFD4A843);
  static const _goldB   = Color(0xFFE8C86A);
  static const _border  = Color(0xFF1E1E2E);
  static const _surface = Color(0xFF13131F);

  // new: Fix #20 — branch index constants, app.dart ke order se match
  static const int _iDashboard   = 0;
  static const int _iChat        = 1;
  static const int _iVoiceWorld  = 2;
  static const int _iPremium     = 3;
  static const int _iProfile     = 4;

  late AnimationController _indicatorCtrl;
  late Animation<double>   _indicatorScale;

  int _prevIndex = 0; // modify: Fix #20 — String se int

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.navigationShell.currentIndex; // modify: Fix #20
    _indicatorCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _indicatorScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorCtrl,
        curve:  Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(AppBottomNav old) {
    super.didUpdateWidget(old);
    // modify: Fix #20 — currentIndex compare karo, route string nahi
    if (old.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _prevIndex = old.navigationShell.currentIndex;
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

    final currentIndex = widget.navigationShell.currentIndex; // new: Fix #20

    // modify: Fix #20 — goBranch use karo, pushReplacement nahi
    // Same tab dobara tap karo toh us branch ki stack reset ho jaati hai
    // (jaisa Instagram/WhatsApp mein hota hai — double-tap-to-top jaisa)
    void safeGo(int index) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == currentIndex,
      );
    }

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
            active:         currentIndex == _iDashboard,
            indicatorScale: _indicatorScale,
            child: NavItem(
              label:  "Home",
              icon:   Icons.home_rounded,
              active: currentIndex == _iDashboard,
              onTap:  () => safeGo(_iDashboard),
            ),
          ),

          // ── Chat ───────────────────────────────
          _NavWrapper(
            active:         currentIndex == _iChat,
            indicatorScale: _indicatorScale,
            child: ChatNavItem(
              unreadCount: widget.unreadCount,
              active:      currentIndex == _iChat,
              onTap:       () => safeGo(_iChat),
            ),
          ),

          // 🔥 Voice World
          _NavWrapper(
            active:         currentIndex == _iVoiceWorld,
            indicatorScale: _indicatorScale,
            child: NavItem(
              label:  "World",
              icon:   Icons.language_rounded,
              active: currentIndex == _iVoiceWorld,
              onTap:  () => safeGo(_iVoiceWorld),
            ),
          ),

          // ── Premium ────────────────────────────
          _NavWrapper(
            active:         currentIndex == _iPremium,
            indicatorScale: _indicatorScale,
            isPremium:      true,
            child: NavItem(
              label:          "Premium",
              icon:           Icons.workspace_premium_rounded,
              active:         currentIndex == _iPremium,
              highlightColor: const Color(0xFFFFD700),
              onTap:          () => safeGo(_iPremium),
            ),
          ),

          // ── Profile ────────────────────────────
          _NavWrapper(
            active:         currentIndex == _iProfile,
            indicatorScale: _indicatorScale,
            child: NavItem(
              label:  "Profile",
              icon:   Icons.person_rounded,
              active: currentIndex == _iProfile,
              onTap:  () => safeGo(_iProfile),
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Nav Wrapper — active indicator + press scale — unchanged
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

  static const _goldA = Color(0xFFD4A843);
  static const _goldB = Color(0xFFE8C86A);

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
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

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

              widget.child,

            ],
          ),
        ),
      ),
    );
  }
}
