import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/socket/global_socket_manager.dart';
import '../../../core/controllers/chat_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {

  List<dynamic> profiles = [];
  bool loading = true;

  bool filterOpen = false;
  int unreadCount = 0;
  bool showActive = true;

  Map<String, String> filters = {
    "gender": "",
    "roleType": "",
    "minAge": "",
    "maxAge": "",
  };

  StreamSubscription? _socketSub;

  @override
  bool get wantKeepAlive => true; // 🔥 important

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
  final token = await ApiClient.getToken();

  if (token == null) {
    if (mounted) context.pushReplacement("/login");
    return;
  }

    final payload = jsonDecode(
      utf8.decode(
        base64Url.decode(
          base64Url.normalize(token.split(".")[1]),
        ),
      ),
    );

    final myId = payload["id"];

    // 🔥 SOCKET START
    await GlobalSocketManager.instance.init(myId);

  // 🔥 Don't block UI
  _fetchProfiles();
  _fetchUnread();
  _listenSocket();

  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) {
      _fetchProfiles();
    }
  });

  // 🔥 Only check profile existence separately
  ApiClient.get("/profile/me").then((profileRes) {
    if (!mounted) return;

    if (profileRes["success"] != true) {
      context.pushReplacement("/create-profile");
    }
  });
  }

  Future<void> _fetchProfiles() async {
  try {
    final response =
        await ApiClient.get("/profile/all", queryParams: filters);

    if (!mounted) return;

    if (response["success"] == true) {
      setState(() {
        profiles = response["data"];
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

  Future<void> _fetchUnread() async {
    try {
      final res = await ApiClient.get("/chat/recent");

      if (!mounted) return;

      if (res["success"] == true) {
        final data = res["data"] as List;
        int total = 0;

        for (var c in data) {
          total += (c["unreadCount"] ?? 0) as int;
        }

        setState(() => unreadCount = total);
        if (mounted) {
          setState(() {
            unreadCount = total;
          });
        }
      }
    } catch (_) {}
  }

  void _listenSocket() {
  final socket = GlobalSocketManager.instance;

  // 🔥 old listener remove
  _socketSub?.cancel();

  _socketSub = socket.messages.listen((message) {

    if (!mounted) return;

    final type = message["type"];

    if (type == "NEW_PROFILE") {
      final newProfile = message["data"];

      if (!profiles.any((p) => p["id"] == newProfile["id"])) {
        setState(() {
          profiles.insert(0, newProfile);
        });
      }
    }

    if (type == "USER_ONLINE") {
      final userId = message["userId"] ?? message["data"]?["userId"];

      setState(() {
        for (var p in profiles) {
          if (p["userId"] == userId) {
            p["user"]["isOnline"] = true;
          }
        }
      });
    }

    if (type == "USER_OFFLINE") {
      final userId = message["userId"] ?? message["data"]?["userId"];

      setState(() {
        for (var p in profiles) {
          if (p["userId"] == userId) {
            p["user"]["isOnline"] = false;
          }
        }
      });
    }

    if (type == "NEW_MESSAGE") {
      final msg = message["data"];

      ChatController.instance.handleNewMessage(msg);

      setState(() {
        unreadCount++;
      });
    }

    if (type == "MESSAGES_READ") {
      _fetchUnread();
    }
  });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (loading && profiles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [

            // SEARCH + FILTER

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search,
                            color: Colors.white54, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style:
                                TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Search...",
                              hintStyle: TextStyle(
                                  color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                GestureDetector(
                  onTap: () =>
                      setState(() => filterOpen = !filterOpen),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune,
                        color: Colors.white70, size: 20),
                  ),
                ),
              ],
            ),

            if (filterOpen) _buildFilterPanel(),

            const SizedBox(height: 14),

            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                itemCount: profiles.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final p = profiles[index];
                  return _ProfileCard(profile: p);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d0d),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration:
                const InputDecoration(labelText: "Gender"),
            items: const [
              DropdownMenuItem(
                  value: "Male", child: Text("Male")),
              DropdownMenuItem(
                  value: "Female", child: Text("Female")),
            ],
            onChanged: (val) =>
                filters["gender"] = val ?? "",
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                loading = true;
              });
              _fetchProfiles();
              filterOpen = false;
            },
            child: const Text("Apply"),
          )
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {

    final online =
        profile["user"]?["isOnline"] == true;

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

            // 🔥 ONLINE DOT
            if (online)
              const Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Colors.green,
                ),
              ),

            // 🔥 CONTENT
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // 🔥 AVATAR
                CircleAvatar(
                  radius: 28,
                  backgroundImage: profile["avatarUrl"] != null &&
                          profile["avatarUrl"].toString().isNotEmpty
                      ? NetworkImage(profile["avatarUrl"])
                      : const AssetImage("assets/profile_placeholder.png")
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
  }
}
