import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await http.get(
        Uri.parse("https://momo-1etm.onrender.com/app/version"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final serverVersion = data["version"] ?? 0;
        final apkUrl = data["apkUrl"];

        // 🔥 DEBUG POPUP (PC ke bina numbers dekhne ke liye)
        _showDebugDialog(currentBuild, serverVersion);

        if (serverVersion > currentBuild) {
          _showUpdateDialog(apkUrl);
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  void _showDebugDialog(int currentBuild, int serverVersion) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Debug Info"),
        content: Text(
          "Current Build: $currentBuild\nServer Version: $serverVersion",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Update Available"),
        content: const Text(
            "A new version of the app is available. Please update."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData.dark(),
    );
  }
}
