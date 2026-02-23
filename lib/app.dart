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

      // ===== LOGIN (No Bottom Nav) =====
      GoRoute(
        path: "/login",
        builder: (context, state) =>
            const LoginScreen(),
      ),

      // ===== CREATE PROFILE (No Bottom Nav) =====
      GoRoute(
        path: "/create-profile",
        builder: (context, state) =>
            const CreateProfileScreen(),
      ),

      // ===== SHELL ROUTE (Bottom Nav Wrapper) =====
      ShellRoute(
        builder: (context, state, child) {
          return AppLayout(child: child);
        },
        routes: [

          GoRoute(
            path: "/dashboard",
            builder: (context, state) =>
                const DashboardScreen(),
          ),

          GoRoute(
            path: "/chat",
            builder: (context, state) =>
                const ChatListScreen(),
          ),

          GoRoute(
            path: "/premium",
            builder: (context, state) =>
                const PremiumScreen(),
          ),

          GoRoute(
            path: "/profile/:id",
            builder: (context, state) {
              final id = state.pathParameters["id"]!;
              return ProfileDetailsScreen(userId: id);
            },
          ),

        ],
      ),

      // ===== CHAT CONVERSATION (Full Screen, No Bottom Nav) =====
      GoRoute(
        path: "/chat/:id",
        builder: (context, state) {
          final id = state.pathParameters["id"]!;
          return ChatConversationScreen(chatUserId: id);
        },
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
