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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      if (widget.userId.isEmpty) {
        setState(() => loading = false);
        return;
      }

      final response =
          await ApiClient.get("/profile/user/${widget.userId}");

      if (response["success"] == true &&
          response["data"] != null) {
        if (mounted) {
          setState(() {
            profile = response["data"];
          });
        }
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

                // 🔙 BACK BUTTON
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),

                const SizedBox(height: 10),

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

                    const CircleAvatar(
                      radius: 70,
                      backgroundImage:
                          AssetImage("assets/profile_placeholder.png"),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  profile!["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "@${profile!["name"] ?? "username"}",
                  style: const TextStyle(color: Colors.white54),
                ),

                const SizedBox(height: 25),

                // 👥 FOLLOW STATS (STATIC 0 for now)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PillStat(title: "Followed", value: "0"),
                    _PillStat(title: "Followers", value: "0"),
                  ],
                ),

                const SizedBox(height: 30),

                // ⭐ LEVEL CARD (STATIC)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16181D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [

                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            "Level 1",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ],
                      ),

                      SizedBox(height: 14),

                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        child: LinearProgressIndicator(
                          value: 0,
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(
                              Color(0xFF2E8BFF)),
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        "0 / 100 XP",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // ➕ FOLLOW BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1F26),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "+ Follow",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 💬 MESSAGE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8BFF),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      final chatUserId =
                          user?["id"]?.toString();

                      if (chatUserId != null &&
                          chatUserId.isNotEmpty) {
                        context.go("/chat/$chatUserId");
                      }
                    },
                    child: const Text(
                      "Message",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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
