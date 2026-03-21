import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_project/shared/layout/app_layout.dart';
import 'package:app_project/features/auth/presentation/login_screen.dart';
import 'package:app_project/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app_project/features/chat/presentation/chat_list_screen.dart';
import 'package:app_project/features/chat/presentation/chat_conversation_screen.dart';
import 'package:app_project/features/profile/presentation/create_profile_screen.dart';
import 'package:app_project/features/profile/presentation/profile_details_screen.dart';
import 'package:app_project/features/profile/presentation/my_profile_screen.dart';
import 'package:app_project/features/profile/presentation/edit_profile_screen.dart';
import 'package:app_project/features/subscription/presentation/premium_screen.dart';
import 'main.dart';
import 'package:app_project/features/room/presentation/room_list_screen.dart';
import 'package:app_project/features/room/presentation/screens/room_screen.dart';
import 'core/debug/global_debug_widget.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  late final GoRouter _router = GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: "/login",
    routes: [

      // ===== LOGIN =====
      GoRoute(
        path: "/login",
        builder: (context, state) =>
            const LoginScreen(),
      ),

      // ===== CREATE PROFILE =====
      GoRoute(
        path: "/create-profile",
        builder: (context, state) =>
            const CreateProfileScreen(),
      ),

      // ===== SHELL ROUTE (BOTTOM NAV WRAPPER) =====
      ShellRoute(
        builder: (context, state, child) {
          return AppLayout(
            child: child,
            unreadCount: 0,
          );
        },
        routes: [

          GoRoute(
            path: "/dashboard",
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),

          GoRoute(
            path: "/chat",
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),

          GoRoute(
            path: "/premium",
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: PremiumScreen(),
            ),
          ),

          GoRoute(
            path: "/rooms",
            pageBuilder: (context, state) =>
                const NoTransitionPage(
               child: RoomListScreen(),
             ),
          ),

          GoRoute(
            path: "/profile",
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: MyProfileScreen(),
            ),
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

      // ===== CHAT CONVERSATION (OUTSIDE SHELL) =====
      GoRoute(
        path: "/room",
        builder: (context, state) {
          final data =
        state.extra as Map<String, dynamic>;

          final roomId = data["roomId"];

          return RoomScreen(
            roomId: roomId,
          );
        },
      ),
      
      GoRoute(
        path: "/chat/:id",
        builder: (context, state) {
          final id = state.pathParameters["id"]!;
          return ChatConversationScreen(chatUserId: id);
        },
      ),
      GoRoute(
        path: "/edit-profile",
        builder: (context, state) {
          final profile =
              state.extra as Map<String, dynamic>;
          return EditProfileScreen(profile: profile);
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

      builder: (context, child) {
        return Stack(
          children: [

            child!, // 🔥 app content

            const GlobalDebugWidget(), // 🔥 debug icon + panel

          ],
        );
      },
    );
   }
 }
