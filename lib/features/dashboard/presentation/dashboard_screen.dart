import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/socket/global_socket_manager.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/data/global_data_manager.dart';

import 'widgets/dashboard_search_bar.dart';
import 'widgets/dashboard_grid.dart';
import 'widgets/dashboard_loading.dart';
import 'widgets/dashboard_empty.dart';

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

  int unreadCount = 0;

  final ScrollController _scrollController =
      ScrollController();

  int page = 1;
  bool hasMore = true;
  bool loadingMore = false;

  StreamSubscription? _socketSub;
  StreamSubscription? _globalSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();

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
      if (mounted) {
        context.pushReplacement("/login");
      }
      return;
    }

    // ===================== LOGIC START =====================

    _listenGlobal();
    _fetchProfiles();
    _fetchUnread();
    _listenSocket();

    ApiClient.get("/profile/me").then((profileRes) {
      if (!mounted) return;
      if (profileRes["success"] != true) {
        context.pushReplacement("/create-profile");
      }
    });

    // ===================== LOGIC END =======================
  }

  // ===================== GLOBAL LISTENER START =====================

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

  // ===================== GLOBAL LISTENER END =======================

  // ===================== FETCH PROFILES START =====================

  Future<void> _fetchProfiles() async {
    final global = GlobalDataManager.instance;

    // instant cache show
    if (global.profiles != null) {
      setState(() {
        profiles = global.profiles!;
        loading = false;
      });
      return;
    }

    try {
      final response = await ApiClient.get(
        "/profile/all",
        queryParams: {
          "page": "1",
          "limit": "20",
        },
      );

      if (!mounted) return;

      if (response["success"] == true) {
        final data = response["data"] as List;

        global.setProfiles(data);

        setState(() {
          profiles = data;
          page = 1;
          hasMore = data.length == 20;
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

  // ===================== FETCH PROFILES END =======================

  // ===================== LOAD MORE START =========================

  Future<void> _loadMore() async {
    if (loadingMore || !hasMore) return;

    loadingMore = true;

    try {
      final res = await ApiClient.get(
        "/profile/all",
        queryParams: {
          "page": (page + 1).toString(),
          "limit": "20",
        },
      );

      if (!mounted) return;

      if (res["success"] == true) {
        final newData = res["data"] as List;

        if (newData.isEmpty) {
          hasMore = false;
        } else {
          page++;
          setState(() {
            profiles.addAll(newData);
          });
        }
      }
    } catch (_) {}

    loadingMore = false;
  }

  // ===================== LOAD MORE END ===========================

  // ===================== UNREAD START ===========================

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

  // ===================== UNREAD END =============================

  // ===================== SOCKET LISTENER START ==================

  void _listenSocket() {
    final socket = GlobalSocketManager.instance;

    _socketSub?.cancel();

    _socketSub = socket.messages.listen((message) {
      if (!mounted) return;

      final type = message["type"];

      if (type == "NEW_PROFILE") {
        final newProfile = message["data"];

        final global = GlobalDataManager.instance;
        global.profiles ??= [];

        if (!global.profiles!.any(
          (p) => p["id"] == newProfile["id"],
        )) {
          global.profiles!.insert(0, newProfile);
          global.notify();
        }
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

  // ===================== SOCKET LISTENER END ====================

  @override
  void dispose() {
    _socketSub?.cancel();
    _globalSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (loading && profiles.isEmpty) {
      return const DashboardLoading();
    }

    if (!loading && profiles.isEmpty) {
      return const DashboardEmpty();
    }

    // ===================== UI START =====================

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Column(
          children: [
            const DashboardSearchBar(),
            const SizedBox(height: 14),
            Expanded(
              child: DashboardGrid(
                profiles: profiles,
                scrollController: _scrollController,
              ),
            ),
          ],
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
