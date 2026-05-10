import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_project/providers/online_users_provider.dart';

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

      if (mounted) setState(() {});
      return;
    }

    try {
      final response =
          await ApiClient.get("/profile/user/${widget.userId}");

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
        setState(() => loading = false);
      }

    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
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
            "/profile/unfollow/${widget.userId}", {});
      } else {
        await ApiClient.post(
            "/profile/follow/${widget.userId}", {});
      }

      if (!mounted) return;

      final currentFollowers =
          profile!["followers"] ?? 0;

      setState(() {
        profile!["isFollowing"] = !isFollowing;
        profile!["followers"] =
            isFollowing
                ? (currentFollowers > 0
                    ? currentFollowers - 1
                    : 0)
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
        ref.watch(onlineUsersProvider)
            .contains(widget.userId);

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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),

                const SizedBox(height: 10),

                Stack(
                  alignment: Alignment.center,
                  children: [

                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: const Color(0xFF2E8BFF),
                        ),
                      ),
                    ),

                    CircleAvatar(
                      radius: 70,
                      backgroundImage: avatar != null
                          ? NetworkImage(avatar)
                          : const AssetImage(
                              "assets/profile_placeholder.png")
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                       child: Container(
                         width: 22,
                         height: 22,
                         decoration: BoxDecoration(
                           color: isOnline
                               ? Colors.green
                               : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                       ),
                     ),
                  ],
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
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    _PillStat(
                        title: "Followed",
                        value: following.toString()),
                    _PillStat(
                        title: "Followers",
                        value: followers.toString()),
                  ],
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16181D),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            "Level $level",
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                                fontSize: 16),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              Colors.white12,
                          valueColor:
                              const AlwaysStoppedAnimation(
                                  Color(0xFF2E8BFF)),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "$xp XP",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isFollowing
                              ? const Color(0xFF444B57)
                              : const Color(0xFF1C1F26),
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),
                    onPressed:
                        actionLoading ? null : _toggleFollow,
                    child: actionLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isFollowing
                                ? "Following"
                                : "+ Follow",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2E8BFF),
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      final chatUserId =
                          user?["id"]?.toString();

                      if (chatUserId != null &&
                          chatUserId.isNotEmpty) {
                        context.push("/chat/$chatUserId");
                      }
                    },
                    child: const Text(
                      "Message",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final String title;
  final String value;

  const _PillStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(30),
        color: const Color(0xFF1C1F26),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
