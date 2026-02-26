import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/socket/global_socket_manager.dart';
import 'dart:async';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with AutomaticKeepAliveClientMixin {

  Map<String, dynamic>? profile;
  bool loading = true;
  StreamSubscription? _socketSub;
  @override
  bool get wantKeepAlive => true;

  @override
void initState() {
  super.initState();
  _fetchProfile();

  _socketSub =
      GlobalSocketManager.instance.messages.listen((data) {

    if (data["type"] == "WALLET_UPDATED") {

      final newBalance = data["balance"];

      if (!mounted) return;
      if (profile == null) return;

      setState(() {
        profile!["user"]["wallet"] = newBalance;
      });
    }
  });
}

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiClient.get("/profile/me");

      if (!mounted) return;

      if (response["success"] == true) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null) {
      return const Center(child: Text("Profile not found"));
    }

    final user = profile!["user"];
    final avatar = profile!["avatarUrl"];
    final name = profile!["name"] ?? "";
    final username = profile!["username"] ?? "";
    final followers = profile!["followers"] ?? 0;
    final following = profile!["following"] ?? 0;
    final level = user?["level"] ?? 1;
    final wallet = user?["wallet"] ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [

            /// 🔥 PROFILE AVATAR WITH CAMERA + LEVEL
            Stack(
              alignment: Alignment.center,
              children: [

                CircleAvatar(
                  radius: 60,
                  backgroundImage: avatar != null
                      ? NetworkImage(avatar)
                      : const AssetImage("assets/profile_placeholder.png")
                          as ImageProvider,
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00F5A0),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),

                Positioned(
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Lv $level",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            Text(
              "@$username",
              style: const TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 25),

            /// 🔥 FOLLOWING / FOLLOWERS BOXES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBox(title: "Following", value: following),
                _StatBox(title: "Followers", value: followers),
              ],
            ),

            const SizedBox(height: 30),

            /// 🔥 EDIT + WALLET ROW
            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1F26),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final result = await context.push<bool>(
                        "/edit-profile",
                        extra: profile,
                      );

                      if (result == true) {
                        _fetchProfile();
                      }
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
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
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final int value;

  const _StatBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
