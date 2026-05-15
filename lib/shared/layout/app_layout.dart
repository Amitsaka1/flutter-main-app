import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/socket_manager.dart';

import 'widgets/app_bottom_nav.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final int unreadCount;

  const AppLayout({
    super.key,
    required this.child,
    this.unreadCount = 0,
  });

  @override
  State<AppLayout> createState() =>
      _AppLayoutState();
}

class _AppLayoutState
    extends State<AppLayout> {

  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();

    final socket =
        SocketManager.instance;

    if (socket != null) {

      _notificationSub =
          socket.notifications.listen(
        (event) {},
      );
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final currentRoute =
        GoRouterState.of(context)
            .uri
            .toString();

    // ================= UI START =================

    return Scaffold(
      backgroundColor:
          const Color(0xFF0a0a0a),

      body: Column(
        children: [

          Expanded(
            child: widget.child,
          ),

          SafeArea(
            top: false,

            child: AppBottomNav(
              route: currentRoute,
              unreadCount:
                  widget.unreadCount,
            ),
          ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
