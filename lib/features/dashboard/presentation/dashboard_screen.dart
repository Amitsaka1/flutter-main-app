import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

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

  WebSocketService? _socket;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.go("/login");
      return;
    }

    final profileRes = await ApiClient.get("/profile/me");

    if (profileRes["success"] != true) {
      if (mounted) context.go("/create-profile");
      return;
    }

    await _fetchProfiles();
    await _fetchUnread();
    _initSocket(token);
  }

  Future<void> _fetchProfiles() async {
    try {
      final response =
          await ApiClient.get("/profile/all", queryParams: filters);

      if (response["success"] == true) {
        if (!mounted) return;
        setState(() {
          profiles = response["data"];
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _fetchUnread() async {
    final res = await ApiClient.get("/chat/recent");

    if (res["success"] == true) {
      final data = res["data"] as List;
      int total = 0;

      for (var c in data) {
        total += (c["unreadCount"] ?? 0) as int;
      }

      if (mounted) {
        setState(() => unreadCount = total);
      }
    }
  }

  void _initSocket(String token) {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(
          base64Url.normalize(token.split(".")[1]))),
    );

    final myId = payload["id"];

    _socket = WebSocketService(userId: myId);
    _socket!.connect();

    _socketSub = _socket!.messages.listen((message) {
      if (message["type"] == "NEW_PROFILE") {
        setState(() {
          if (!profiles.any(
              (p) => p["id"] == message["data"]["id"])) {
            profiles.insert(0, message["data"]);
          }
        });
      }

      if (message["type"] == "NEW_MESSAGE" ||
          message["type"] == "MESSAGES_READ") {
        _fetchUnread();
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [

            // ================= SEARCH + FILTER =================

            Row(
              children: [

                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [

                        const Icon(Icons.search,
                            color: Colors.white54, size: 20),

                        const SizedBox(width: 8),

                        const Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Search...",
                              hintStyle:
                                  TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.card_giftcard,
                                color: Colors.white70, size: 22),

                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  "2",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

            const SizedBox(height: 12),

            // ================= ACTIVE / GIFTS =================

            Row(
              children: [

                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => showActive = true),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: showActive
                            ? const Color(0xFF2a2a2a)
                            : const Color(0xFF1a1a1a),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          "🔥 Active",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => showActive = false),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: !showActive
                            ? const Color(0xFF2a2a2a)
                            : const Color(0xFF1a1a1a),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          "🌟 Gifts",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ================= PROFILE GRID =================

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
            decoration: const InputDecoration(labelText: "Gender"),
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
            ],
            onChanged: (val) => filters["gender"] = val ?? "",
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Role"),
            items: const [
              DropdownMenuItem(value: "Top", child: Text("Top")),
              DropdownMenuItem(value: "Bottom", child: Text("Bottom")),
              DropdownMenuItem(value: "Lesbian", child: Text("Lesbian")),
            ],
            onChanged: (val) => filters["roleType"] = val ?? "",
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _fetchProfiles();
              setState(() => filterOpen = false);
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

    final online = profile["user"]?["isOnline"] == true;

    final String? userId =
        profile["userId"]?.toString();   // ✅ CORRECT FIELD

    return GestureDetector(
      onTap: () {
        if (userId != null && userId.isNotEmpty) {
          context.go("/profile/$userId");
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
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Colors.green,
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(profile["name"] ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("${profile["gender"] ?? ""} • ${profile["age"] ?? ""}"),
                Text(profile["roleType"] ?? ""),
                Text(profile["havePlace"] == true
                    ? "Has Place"
                    : "No Place"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
