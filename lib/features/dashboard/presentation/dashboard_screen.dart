import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/socket/global_socket_manager.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/data/global_data_manager.dart'; // ✅ NEW

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

  Map<String, String> filters = {
    "gender": "",
    "roleType": "",
    "minAge": "",
    "maxAge": "",
  };

  // 🔥 PAGINATION + SCROLL
  final ScrollController _scrollController = ScrollController();

  int page = 1;
  bool hasMore = true;
  bool loadingMore = false;

  StreamSubscription? _socketSub;
  StreamSubscription? _globalSub; // ✅ NEW

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();

    // 🔥 SCROLL LISTENER (LOAD MORE TRIGGER)
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }
  

  Future<void> _init() async {

    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.pushReplacement("/login");
      return;
    }

//    final payload = jsonDecode(
  //    utf8.decode(
  //      base64Url.decode(
  //        base64Url.normalize(token.split(".")[1]),
  //      ),
 //     ),
//    );

 //   final myId = payload["id"];

  //  await GlobalSocketManager.instance.init(myId);

    _listenGlobal();   // ✅ NEW
    _fetchProfiles();
    _fetchUnread();
    _listenSocket();

    ApiClient.get("/profile/me").then((profileRes) {
      if (!mounted) return;
      if (profileRes["success"] != true) {
        context.pushReplacement("/create-profile");
      }
    });
  }

  // =========================
  // 🔥 GLOBAL LISTENER
  // =========================

  void _listenGlobal() {
    final global = GlobalDataManager.instance;

    _globalSub = global.stream.listen((_) {
      if (!mounted) return;

      if (global.profiles != null) {
        setState(() {
          profiles = global.profiles!;
          loading = false;
        });
      }
    });
  }

  // =========================
  // 🔥 FETCH PROFILES (CACHE)
  // =========================

  Future<void> _fetchProfiles() async {

    final global = GlobalDataManager.instance;

    // ✅ instant load
    if (global.profiles != null) {
      setState(() {
        profiles = global.profiles!;
        loading = false;
      });
      return;
    }

    try {
      final response =
          await ApiClient.get("/profile/all", queryParams: filters);

      if (!mounted) return;

      if (response["success"] == true) {

        global.setProfiles(response["data"]); // 🔥 SAVE GLOBAL

        setState(() {
          profiles = response["data"];
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

  // =========================
  // 🔥 FETCH UNREAD
  // =========================

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
      }
    } catch (_) {}
  }

  // =========================
  // 🔥 SOCKET LISTENER
  // =========================

  void _listenSocket() {

    final socket = GlobalSocketManager.instance;
    final global = GlobalDataManager.instance;

    _socketSub?.cancel();

    _socketSub = socket.messages.listen((message) {

      if (!mounted) return;

      final type = message["type"];

      if (type == "NEW_PROFILE") {
        final newProfile = message["data"];

        if (global.profiles != null &&
            !global.profiles!.any((p) => p["id"] == newProfile["id"])) {

          global.profiles!.insert(0, newProfile); // 🔥 GLOBAL UPDATE
          global.notify();

        }
      }

      if (type == "USER_ONLINE" || type == "USER_OFFLINE") {
        setState(() {}); // only UI refresh
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
    _globalSub?.cancel(); // ✅ NEW
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

            // SEARCH

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
              ],
            ),

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
}

class _ProfileCard extends StatelessWidget {
  final dynamic profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {

    final socket = GlobalSocketManager.instance;

    final online = socket.onlineUsers.contains(
      profile["userId"]?.toString(),
    );

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
