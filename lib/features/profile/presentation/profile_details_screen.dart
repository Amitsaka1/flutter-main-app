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

    return Scaffold(
      appBar: AppBar(
        title: Text(profile!["name"] ?? ""),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Text(
                  profile!["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                if (user?["isOnline"] == true)
                  const Text(
                    "● Online",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            if (user?["isOnline"] != true &&
                user?["lastSeen"] != null)
              Padding(
                padding:
                    const EdgeInsets.only(top: 4),
                child: Text(
                  formatLastSeen(user["lastSeen"]),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius:
                    BorderRadius.circular(15),
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

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.cyanAccent,
                  padding:
                      const EdgeInsets.all(12),
                ),
                onPressed: () {
                  final chatUserId =
                      profile!["user"]?["id"]
                          ?.toString();

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
            )
          ],
        ),
      ),
    );
  }
}
