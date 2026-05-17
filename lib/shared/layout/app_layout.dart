import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/socket_manager.dart';

import 'widgets/app_bottom_nav.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final int    unreadCount;

  const AppLayout({
    super.key,
    required this.child,
    this.unreadCount = 0,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg      = Color(0xFF0A0A0F);
  static const _goldA   = Color(0xFFD4A843);
  static const _border  = Color(0xFF1E1E2E);
  static const _surface = Color(0xFF0E0E18);

  StreamSubscription? _notificationSub;

  // ── Nav entrance animation ───────────────────
  late AnimationController _navCtrl;
  late Animation<double>   _navSlide;
  late Animation<double>   _navFade;

  @override
  void initState() {
    super.initState();

    // Nav entrance
    _navCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _navSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _navCtrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _navFade = CurvedAnimation(
      parent: _navCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    // ===================== LOGIC START =====================

    final socket = SocketManager.instance;

    if (socket != null) {
      _notificationSub = socket.notifications.listen((event) {});
    }

    // ===================== LOGIC END =======================
  }

  @override
  void dispose() {
    _navCtrl.dispose();
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    final currentRoute = GoRouterState.of(context).uri.toString();

    // ===================== UI START =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0A0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [

            // ── Main content ───────────────────
            Expanded(
              child: widget.child,
            ),

            // ── Bottom nav ─────────────────────
            FadeTransition(
              opacity: _navFade,
              child: AnimatedBuilder(
                animation: _navSlide,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _navSlide.value),
                  child: child,
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // Gold hairline top border
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _goldA.withOpacity(0.20),
                              _goldA.withOpacity(0.35),
                              _goldA.withOpacity(0.20),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),

                      // Nav background
                      Container(
                        decoration: BoxDecoration(
                          color: _surface.withOpacity(0.97),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius:   24,
                              offset: const Offset(0, -6),
                            ),
                            BoxShadow(
                              color: _goldA.withOpacity(0.04),
                              blurRadius:   40,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: AppBottomNav(
                          route:       currentRoute,
                          unreadCount: widget.unreadCount,
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
