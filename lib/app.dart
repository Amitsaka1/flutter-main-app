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
import 'package:flutter/foundation.dart';
// 🔥 VOICE WORLD — NEW
import 'package:app_project/features/voice_world/presentation/screens/voice_world_screen.dart';

import 'main.dart';
import 'core/debug/global_debug_widget.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  // modify: Fix #20 — ShellRoute → StatefulShellRoute.indexedStack
  //
  // Problem: Plain ShellRoute + bottom-nav ka pushReplacement() har tab
  //          switch pe poora screen DISPOSE + RECREATE karta tha
  //          (koi IndexedStack nahi tha) — isiliye chat list ka
  //          instant-cache-open kabhi kaam nahi karta tha
  //
  // Fix: Sab tabs IndexedStack mein zinda rehte hain ab — sirf
  //      visibility switch hoti hai. State/cache/animation preserve hota hai
  //
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

      // ===== SHELL ROUTE (BOTTOM NAV WRAPPER) — FIXED =====
      // new: Fix #20 — StatefulShellRoute.indexedStack use kiya
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppLayout(
            navigationShell: navigationShell,
            unreadCount:     0,
          );
        },
        branches: [

          // ── Dashboard ──────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/dashboard",
                pageBuilder: (context, state) =>
                    const NoTransitionPage(
                  child: DashboardScreen(),
                ),
              ),
            ],
          ),

          // ── Chat ───────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/chat",
                pageBuilder: (context, state) =>
                    const NoTransitionPage(
                  child: ChatListScreen(),
                ),
              ),
            ],
          ),

          // ── Voice World ────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/voice-world",
                pageBuilder: (context, state) =>
                    const NoTransitionPage(
                  child: VoiceWorldScreen(),
                ),
              ),
            ],
          ),

          // ── Premium ────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/premium",
                pageBuilder: (context, state) =>
                    const NoTransitionPage(
                  child: PremiumScreen(),
                ),
              ),
            ],
          ),

          // ── Profile ────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/profile",
                pageBuilder: (context, state) =>
                    const NoTransitionPage(
                  child: MyProfileScreen(),
                ),
              ),
            ],
          ),

        ],
      ),

      // ===== CHAT CONVERSATION (OUTSIDE SHELL) — unchanged =====
      GoRoute(
        path: "/chat/:id",
        builder: (context, state) {
          final id     = state.pathParameters["id"]!;
          final extras = state.extra as Map<String, dynamic>?;

          return ChatConversationScreen(
            chatUserId:        id,
            chatUserName:      extras?["name"],
            chatUserPhotoUrl:  extras?["avatar"],
            chatUserLastSeen:  extras?["lastSeen"],
            initialIsOnline:   extras?["isOnline"] ?? false,
          );
        },
      ),

      // new: Fix #20 — /profile/:id shell se BAHAR move kiya
      // Pehle ShellRoute ke andar tha — ab /chat/:id jaisa top-level route
      // Bottom nav automatically hide ho jaata hai (jaisa chat conversation mein)
      GoRoute(
        path: "/profile/:id",
        builder: (context, state) {
          final id = state.pathParameters["id"]!;
          return ProfileDetailsScreen(userId: id);
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
            child!,
            if (!kReleaseMode) const GlobalDebugWidget(),
          ],
        );
      },
    );
  }
}
