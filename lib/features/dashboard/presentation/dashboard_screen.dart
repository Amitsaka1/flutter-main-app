import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../shared/layout/app_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {

  List<dynamic> profiles = [];
  bool loading = true;

  bool filterOpen = false;
  int unreadCount = 0;

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

    final profileRes =
        await ApiClient.get("/profile/me");

    if (profileRes["success"] != true) {
      if (mounted) context.go("/create-profile");
      return;
    }

    await _fetchProfiles();
    await _fetchUnread();
    _initSocket(token);
  }

  // =========================
  // FETCH PROFILES
  // =========================
  Future<void> _fetchProfiles() async {
    try {

      final response =
          await ApiClient.get("/profile/all",
              queryParams: filters);

      if (response["success"] == true) {
        if (!mounted) return;
        setState(() {
          profiles = response["data"];
          loading = false;
        });
      }

    } catch (_) {
      setState(() => loading = false);
    }
  }

  // =========================
  // FETCH UNREAD
  // =========================
  Future<void> _fetchUnread() async {
    final res =
        await ApiClient.get("/chat/recent");

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

  // =========================
  // SOCKET
  // =========================
  void _initSocket(String token) {

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(
          base64Url.normalize(token.split(".")[1]))),
    );

    final myId = payload["id"];

    _socket = WebSocketService(userId: myId);
    _socket!.connect();

    _socketSub =
        _socket!.messages.listen((message) {

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

  // =========================
  // UI
  // =========================

  // =========================
// UI
// =========================
@override
Widget build(BuildContext context) {

  if (loading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Column(
      children: [

        // 🔥 FILTER BUTTON (Neon Style)
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () =>
                setState(() =>
                    filterOpen = !filterOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00F5A0),
                    Color(0xFFFF00C8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    blurRadius: 15,
                  )
                ],
              ),
              child: const Text(
                "🔎 Filter",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        if (filterOpen) _buildFilterPanel(),

        const SizedBox(height: 20),

        // 🔥 CYBER STAT BOXES
        Row(
          children: const [
            Expanded(child: _CyberStatBox("🔥 Active")),
            SizedBox(width: 15),
            Expanded(child: _CyberStatBox("🌟 Gifts")),
          ],
        ),

        const SizedBox(height: 20),

        Expanded(
          child: GridView.builder(
            itemCount: profiles.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final p = profiles[index];
              return _ProfileCard(profile: p);
            },
          ),
        )
      ],
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
                  value: "Male",
                  child: Text("Male")),
              DropdownMenuItem(
                  value: "Female",
                  child: Text("Female")),
            ],
            onChanged: (val) =>
                filters["gender"] = val ?? "",
          ),

          DropdownButtonFormField<String>(
            decoration:
                const InputDecoration(labelText: "Role"),
            items: const [
              DropdownMenuItem(
                  value: "Top",
                  child: Text("Top")),
              DropdownMenuItem(
                  value: "Bottom",
                  child: Text("Bottom")),
              DropdownMenuItem(
                  value: "Lesbian",
                  child: Text("Lesbian")),
            ],
            onChanged: (val) =>
                filters["roleType"] = val ?? "",
          ),

          TextField(
            decoration:
                const InputDecoration(labelText: "Min Age"),
            keyboardType: TextInputType.number,
            onChanged: (val) =>
                filters["minAge"] = val,
          ),

          TextField(
            decoration:
                const InputDecoration(labelText: "Max Age"),
            keyboardType: TextInputType.number,
            onChanged: (val) =>
                filters["maxAge"] = val,
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

// =============================
// PROFILE CARD
// =============================
class _ProfileCard extends StatelessWidget {

  final dynamic profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {

    final online =
        profile["user"]?["isOnline"] == true;

    return GestureDetector(
      onTap: () =>
          context.go("/profile/${profile["userId"]}"),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF0f0f0f),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
              blurRadius: 15,
            )
          ],
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
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(profile["name"],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 5),
                Text(
                    "${profile["gender"]} • ${profile["age"]}",
                    style: const TextStyle(color: Colors.white70)),
                Text(profile["roleType"],
                    style: const TextStyle(color: Colors.white60)),
                Text(profile["havePlace"]
                    ? "Has Place"
                    : "No Place",
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================
class _StatBox extends StatelessWidget {
  final String text;
  const _StatBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
