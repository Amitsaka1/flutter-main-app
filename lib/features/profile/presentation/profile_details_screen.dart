import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import 'package:app_project/providers/online_users_provider.dart';

import 'widgets/profile_details_avatar.dart';
import 'widgets/profile_pill_stat.dart';
import 'widgets/profile_xp_card.dart';
import 'widgets/profile_follow_button.dart';
import 'widgets/profile_message_button.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileDetailsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState
    extends ConsumerState<ProfileDetailsScreen> {
  /// 🔥 GLOBAL CACHE
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  Map<String, dynamic>? profile;
  bool loading = true;
  bool actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    /// 🔥 CACHE HIT (INSTANT OPEN)
    if (_profileCache.containsKey(widget.userId)) {
      profile = _profileCache[widget.userId];
      loading = false;

      if (mounted) {
        setState(() {});
      }
      /// 🔥 continue background refresh
    }

    try {
      final response = await ApiClient.get(
        "/profile/user/${widget.userId}",
      );

      if (!mounted) return;

      if (response["success"] == true &&
          response["data"] != null) {
        profile = response["data"];

        /// 🔥 SAVE CACHE
        _profileCache[widget.userId] = profile!;

        setState(() {
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (profile == null || actionLoading) return;

    final bool isFollowing = profile!["isFollowing"] ?? false;

    setState(() => actionLoading = true);

    try {
      if (isFollowing) {
        await ApiClient.post(
          "/profile/unfollow/${widget.userId}",
          {},
        );
      } else {
        await ApiClient.post(
          "/profile/follow/${widget.userId}",
          {},
        );
      }

      if (!mounted) return;

      final currentFollowers = profile!["followers"] ?? 0;

      setState(() {
        profile!["isFollowing"] = !isFollowing;
        profile!["followers"] = isFollowing
            ? (currentFollowers > 0 ? currentFollowers - 1 : 0)
            : currentFollowers + 1;
        actionLoading = false;
      });

      /// 🔥 UPDATE CACHE
      _profileCache[widget.userId] = profile!;
    } catch (_) {
      if (mounted) {
        setState(() => actionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text("Profile not found")),
      );
    }

    final user = profile!["user"];

    final isOnline =
        ref.watch(onlineUsersProvider).contains(widget.userId);

    final name = profile!["name"] ?? "";
    final username = profile!["username"] ?? name;
    final avatar = profile!["avatarUrl"];
    final followers = profile!["followers"] ?? 0;
    final following = profile!["following"] ?? 0;
    final xp = user?["xp"] ?? 0;
    final level = user?["level"] ?? 1;
    final isFollowing = profile!["isFollowing"] ?? false;

    final progress = (xp % 100) / 100;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F1115),
              Color(0xFF0B0C10),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: Column(
              children: [
                // ================= UI START =================

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),

                const SizedBox(height: 10),

                ProfileDetailsAvatar(
                  avatar: avatar,
                  isOnline: isOnline,
                ),

                const SizedBox(height: 20),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "@$username",
                  style: const TextStyle(color: Colors.white54),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ProfilePillStat(
                      title: "Followed",
                      value: following.toString(),
                    ),
                    ProfilePillStat(
                      title: "Followers",
                      value: followers.toString(),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                ProfileXpCard(
                  level: level,
                  xp: xp,
                  progress: progress,
                ),

                const SizedBox(height: 35),

                ProfileFollowButton(
                  isFollowing: isFollowing,
                  actionLoading: actionLoading,
                  onTap: _toggleFollow,
                ),

                const SizedBox(height: 15),

                ProfileMessageButton(
                  onTap: () {
                    final chatUserId = user?["id"]?.toString();

                    if (chatUserId != null && chatUserId.isNotEmpty) {
                      context.push("/chat/$chatUserId");
                    }
                  },
                ),

                const SizedBox(height: 80),

                // ================= UI END =================
              ],
            ),
          ),
        ),
      ),
    );
  }
}
