import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_project/shared/layout/app_layout.dart';
import 'package:app_project/features/auth/presentation/login_screen.dart';
import 'package:app_project/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app_project/features/chat/presentation/chat_list_screen.dart';
import 'package:app_project/features/chat/presentation/chat_conversation_screen.dart';
import 'package:app_project/features/profile/presentation/create_profile_screen.dart';
import 'package:app_project/features/profile/presentation/profile_details_screen.dart';
import 'package:app_project/features/subscription/presentation/premium_screen.dart';

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final GoRouter _router = GoRouter(
    initialLocation: "/login",
    routes: [
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/dashboard",
        builder: (context, state) =>
            AppLayout(child: const DashboardScreen()),
      ),
      GoRoute(
        path: "/create-profile",
        builder: (context, state) =>
            const CreateProfileScreen(),
      ),
      GoRoute(
        path: "/chat",
        builder: (context, state) =>
            AppLayout(child: const ChatListScreen()),
      ),
      GoRoute(
        path: "/chat/:id",
        builder: (context, state) {
          final id = state.pathParameters["id"]!;
          return ChatConversationScreen(chatUserId: id);
        },
      ),
      GoRoute(
        path: "/profile/:id",
        builder: (context, state) {
          final id = state.pathParameters["id"]!;
          return ProfileDetailsScreen(userId: id);
        },
      ),
      GoRoute(
        path: "/premium",
        builder: (context, state) =>
            AppLayout(child: const PremiumScreen()),
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
