import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secure_subscription_app/shared/layout/app_layout.dart';
import 'package:secure_subscription_app/features/auth/presentation/login_screen.dart';
import 'package:secure_subscription_app/features/chat/presentation/chat_screen.dart';
import 'package:secure_subscription_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:secure_subscription_app/features/subscription/presentation/premium_screen.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _router = GoRouter(
    initialLocation: "/login",
    routes: [
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/dashboard",
        builder: (context, state) => AppLayout(
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: "/chat",
        builder: (context, state) => AppLayout(
          child: const ChatScreen(),
        ),
      ),
      GoRoute(
        path: "/premium",
        builder: (context, state) => AppLayout(
          child: const PremiumScreen(),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData.dark(),
    );
  }
}
