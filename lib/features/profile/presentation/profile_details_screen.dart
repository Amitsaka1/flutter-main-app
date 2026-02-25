import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final String userId;

  const ProfileDetailsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState
    extends State<ProfileDetailsScreen> {

  Map<String, dynamic>? profile;
  bool loading = true;
  bool actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response =
          await ApiClient.get("/profile/user/${widget.userId}");

      if (!mounted) return;

      if (response["success"] == true &&
          response["data"] != null) {
        setState(() {
          profile = response["data"];
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

    } catch (e) {
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
