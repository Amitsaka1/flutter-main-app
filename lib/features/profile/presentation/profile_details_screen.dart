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

  String formatLastSeen(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();

    final sameDay =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final yesterday =
        now.subtract(const Duration(days: 1));

    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    if (sameDay) {
      return "Last seen today at ${_formatTime(date)}";
    }

    if (isYesterday) {
      return "Last seen yesterday at ${_formatTime(date)}";
    }

    return "Last seen ${date.day}/${date.month}/${date.year} ${_formatTime(date)}";
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : date.hour;
    final minute =
        date.minute.toString().padLeft(2, '0');
    final period =
        date.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text("Profile not found"),
        ),
      );
    }

    final user = profile!["user"];
    final bool online = user?["isOnline"] == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1a002b),
              Color(0xFF000000),
              Color(0xFF001f2f),
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

                // 🔥 PROFILE IMAGE
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF00F5A0),
                            Color(0xFFFF00C8),
                          ],
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          AssetImage("assets/profile_placeholder.png"),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 🔹 NAME
                Text(
                  profile!["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                if (online)
                  const Text(
                    "● Online",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                if (!online && user?["lastSeen"] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formatLastSeen(user["lastSeen"]),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),

                const SizedBox(height: 25),

                // 🔹 INFO CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2a003f),
                        Color(0xFF001f2f),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                          "${profile!["gender"] ?? ""} • ${profile!["age"] ?? ""}"),
                      const SizedBox(height: 6),
                      Text(profile!["roleType"] ?? ""),
                      const SizedBox(height: 6),
                      Text(profile!["havePlace"] == true
                          ? "Has Place"
                          : "No Place"),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 BUTTONS
                Row(
                  children: [

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          padding:
                              const EdgeInsets.all(14),
                        ),
                        onPressed: () {},
                        child: const Text("Follow"),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.cyanAccent,
                          padding:
                              const EdgeInsets.all(14),
                        ),
                        onPressed: () {
                          final chatUserId =
                              user?["id"]?.toString();

                          if (chatUserId != null &&
                              chatUserId.isNotEmpty) {
                            context.go(
                                "/chat/$chatUserId");
                          }
                        },
                        child: const Text(
                          "💬 Message",
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
