import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {

  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiClient.get("/profile/me");

      if (response["success"] == true) {
        setState(() {
          profile = response["data"];
        });
      }
    } catch (_) {}

    if (mounted) {
      setState(() => loading = false);
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

    final name = profile!["name"] ?? "No Name";
    final username = profile!["username"] ?? "username";
    final avatar = profile!["avatarUrl"];
    final followers = profile!["followers"] ?? 0;
    final following = profile!["following"] ?? 0;
    final xp = user?["xp"] ?? 0;
    final level = user?["level"] ?? 1;
    final wallet = user?["wallet"] ?? 0;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [

                // 🔥 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "🔥 Naxorah",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00C6FF),
                            Color(0xFF7F00FF),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            wallet.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 40),

                // 🧑 PROFILE IMAGE
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
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1C1F26),
                          border: Border.all(
                            color: Colors.white24,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    )
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

                const SizedBox(height: 30),

                // 👥 FOLLOW STATS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PillStat(title: "Followed", value: following.toString()),
                    _PillStat(title: "Followers", value: followers.toString()),
                  ],
                ),

                const SizedBox(height: 30),

                // ⭐ LEVEL CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16181D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            "Level $level",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(
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

                // ✏ EDIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1F26),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                const Text(
                  "Frames & Gifts will appear here",
                  style: TextStyle(color: Colors.white30),
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
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
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
