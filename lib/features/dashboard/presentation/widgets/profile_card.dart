import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_project/providers/online_users_provider.dart';
import 'online_indicator.dart';

class ProfileCard extends ConsumerWidget {
  final dynamic profile;

  const ProfileCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ===================== UI START =====================

    final onlineUsers = ref.watch(onlineUsersProvider);

    final online = onlineUsers.contains(
      profile["userId"]?.toString(),
    );

    final String? userId =
        profile["userId"]?.toString();

    return GestureDetector(
      onTap: () {
        if (userId != null && userId.isNotEmpty) {
          context.push("/profile/$userId");
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0f0f0f),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [

            if (online)
              const Positioned(
                top: 0,
                right: 0,
                child: OnlineIndicator(),
              ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                CircleAvatar(
                  radius: 28,
                  backgroundImage: profile["avatarUrl"] != null &&
                          profile["avatarUrl"].toString().isNotEmpty
                      ? NetworkImage(profile["avatarUrl"])
                      : const AssetImage(
                              "assets/profile_placeholder.png")
                          as ImageProvider,
                ),

                const SizedBox(height: 10),

                Text(
                  profile["name"] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "${profile["gender"] ?? ""} • ${profile["age"] ?? ""}",
                ),

                Text(profile["roleType"] ?? ""),

                Text(
                  profile["havePlace"] == true
                      ? "Has Place"
                      : "No Place",
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
