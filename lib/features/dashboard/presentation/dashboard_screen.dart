import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/socket/global_socket_manager.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/data/global_data_manager.dart';
import '../../../core/session/user_session.dart';
import 'package:app_project/providers/user_locations_provider.dart';
import 'package:app_project/core/riverpod/app_container.dart';

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
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _accent    = Color(0xFF6C63FF);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  // ── State ────────────────────────────────────
  List<dynamic> profiles  = [];
  bool loading            = true;
  int  unreadCount        = 0;

  final ScrollController _scrollController = ScrollController();

  int  page        = 1;
  bool hasMore     = true;
  bool loadingMore = false;

  StreamSubscription? _socketSub;
  StreamSubscription? _globalSub;

  // ── UI Animations ────────────────────────────
  late AnimationController _headerCtrl;
  late AnimationController _badgeCtrl;
  late Animation<double>   _headerFade;
  late Animation<double>   _headerSlide;
  late Animation<double>   _badgePulse;

  // Header shrink on scroll
  double _headerOpacity = 1.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Header entrance
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _headerSlide = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(
        parent: _headerCtrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Badge pulse
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _badgePulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeInOut),
    );

    // Scroll → header opacity
    _scrollController.addListener(() {
      final offset = _scrollController.position.pixels;
      setState(() {
        _headerOpacity = (1.0 - (offset / 80).clamp(0.0, 0.4));
      });

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });

    _init();
  }

  // ===================== LOGIC START =====================

  Future<void> _init() async {
    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.pushReplacement("/login");
      return;
    }

    _listenGlobal();
    _fetchProfiles();
    _fetchUnread();
    _listenSocket();
    ChatController.instance.loadChats();
    _fetchAllLocations();

    ApiClient.get("/profile/me").then((profileRes) {
      if (!mounted) return;
      if (profileRes["success"] != true) {
        context.pushReplacement("/create-profile");
        return;
      }

      // fix: UserSession mein profile cache karo
      // Voice World join pe hamesha sahi name/avatar/level milega
      // Zero extra API call — ye call pehle se ho rahi thi
      final data = profileRes["data"] as Map<String, dynamic>?;
      if (data != null) {
        UserSession.setProfile(
          name:      data["name"]             as String? ?? "",
          avatarUrl: data["avatarUrl"]        as String?,
          level:     (data["user"]?["level"]) as int?    ?? 1,
        );
      }
    });
  }

  // ===================== GLOBAL LISTENER START =====================

  void _listenGlobal() {
    final global = GlobalDataManager.instance;

    _globalSub = global.stream.listen((_) {
      if (!mounted) return;
      if (global.profiles != null) {
        setState(() {
          profiles = global.profiles!;
          loading  = false;
        });
      }
    });
  }

  // ===================== GLOBAL LISTENER END =======================

  // ===================== FETCH PROFILES START =====================

  Future<void> _fetchProfiles() async {
    final global = GlobalDataManager.instance;

    // ✅ Cache se instant dikhao — loading nahi
    if (global.profiles != null) {
      setState(() {
        profiles = global.profiles!;
        loading  = false;
      });
      // ✅ Return nahi — background mein fresh data bhi lao
    }

    try {
      final response = await ApiClient.get(
        "/profile/all",
        queryParams: {"page": "1", "limit": "20"},
      );

      if (!mounted) return;

      if (response["success"] == true) {
        final data = response["data"] as List;
        await global.setProfiles(data); // ✅ await add kiya
        setState(() {
          profiles = data;
          page     = 1;
          hasMore  = data.length == 20;
          loading  = false;
        });
      } else {
        if (mounted) setState(() => loading = false);
      }
    } catch (_) {
      // ✅ Offline hai — cache already dikh raha hai — koi error nahi
      if (mounted) setState(() => loading = false);
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
          "page":  (page + 1).toString(),
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
          setState(() => profiles.addAll(newData));
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
        final data  = res["data"] as List;
        int   total = 0;
        for (var c in data) {
          total += (c["unreadCount"] ?? 0) as int;
        }
        setState(() => unreadCount = total);
      }
    } catch (_) {}
  }

  // ===================== UNREAD END =============================

  // ===================== FETCH ALL LOCATIONS START ==================

  Future<void> _fetchAllLocations() async {
    try {
      final res = await ApiClient.get("/profile/locations/all");
      if (!mounted) return;

      if (res["success"] == true) {
        final locations = res["locations"] as List<dynamic>? ?? [];
        globalProviderContainer
            .read(userLocationsProvider.notifier)
            .setAllLocations(locations);
        debugPrint("📍 Locations loaded on restart: ${locations.length} users");
      }
    } catch (e) {
      debugPrint("📍 Fetch locations failed (silent): $e");
    }
  }

  // ===================== FETCH ALL LOCATIONS END ====================

  // ===================== SOCKET LISTENER START ==================

  void _listenSocket() {
    final socket = GlobalSocketManager.instance;
    _socketSub?.cancel();

    _socketSub = socket.messages.listen((message) {
      if (!mounted) return;

      final type = message["type"];

      if (type == "NEW_PROFILE") {
        final newProfile = message["data"];
        final global     = GlobalDataManager.instance;
        global.profiles ??= [];

        if (!global.profiles!.any((p) => p["id"] == newProfile["id"])) {
          global.profiles!.insert(0, newProfile);
          global.notify();
        }
      }

      if (type == "PROFILE_UPDATED") {
        final data          = message["data"];
        final updatedUserId = data["userId"]?.toString();
        final newAvatarUrl  = data["avatarUrl"]?.toString();
        final global        = GlobalDataManager.instance;

        if (updatedUserId != null && newAvatarUrl != null && global.profiles != null) {
          final idx = global.profiles!.indexWhere(
            (p) => p["userId"]?.toString() == updatedUserId,
          );
          if (idx != -1) {
            global.profiles![idx] = {
              ...Map<String, dynamic>.from(global.profiles![idx]),
              "avatarUrl": newAvatarUrl,
            };
            global.notify();
          }
        }
      }

      if (type == "NEW_MESSAGE") {
        final msg = message["data"];
        ChatController.instance.handleNewMessage(msg);
        setState(() => unreadCount++);
      }

      if (type == "MESSAGES_READ") {
        _fetchUnread();
      }
    });
  }

  // ===================== SOCKET LISTENER END ====================

  // ===================== LOGIC END =======================

  @override
  void dispose() {
    _headerCtrl.dispose();
    _badgeCtrl.dispose();
    _socketSub?.cancel();
    _globalSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Header — logo + title + chat button
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: AnimatedBuilder(
        animation: _headerSlide,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _headerSlide.value),
          child: child,
        ),
        child: Opacity(
          opacity: _headerOpacity.clamp(0.6, 1.0),
          child: Row(
            children: [

              // ── Brand mark ──────────────────────
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_goldA, _goldC],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _goldA.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: Color(0xFF0A0A0F),
                ),
              ),

              const SizedBox(width: 12),

              // ── Title block ─────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [_goldA, _goldB],
                    ).createShader(b),
                    child: const Text(
                      "Discover",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    "Find your people",
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Chat icon + unread badge ─────────
              GestureDetector(
                onTap: () => context.push("/chats"),
                child: AnimatedBuilder(
                  animation: _badgePulse,
                  builder: (_, child) => Transform.scale(
                    scale: unreadCount > 0 ? _badgePulse.value : 1.0,
                    child: child,
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: unreadCount > 0
                            ? _goldA.withOpacity(0.5)
                            : _border,
                        width: 1,
                      ),
                      boxShadow: unreadCount > 0
                          ? [
                              BoxShadow(
                                color: _goldA.withOpacity(0.15),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          unreadCount > 0
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: unreadCount > 0 ? _goldA : _textMuted,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _goldA,
                                boxShadow: [
                                  BoxShadow(
                                    color: _goldA.withOpacity(0.8),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Load-more footer spinner
  // ─────────────────────────────────────────────

  Widget _buildFooter() {
    if (!loadingMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              valueColor: AlwaysStoppedAnimation(_goldA.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "Loading more...",
            style: TextStyle(
              color: _textMuted,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Decorative top glow strip
  // ─────────────────────────────────────────────

  Widget _buildTopGlow() {
    return Positioned(
      top: 0,
      left: 60,
      right: 60,
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              _goldA.withOpacity(0.25),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ── Status bar style ────────────────────────
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:       Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Loading ─────────────────────────────────
    if (loading && profiles.isEmpty) {
      return const DashboardLoading();
    }

    // ── Empty ────────────────────────────────────
    if (!loading && profiles.isEmpty) {
      return const DashboardEmpty();
    }

    // ===================== UI START =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: _bg,
        child: SafeArea(
          child: Stack(
            children: [

              // ── Top glow strip ─────────────────
              _buildTopGlow(),

              // ── Main layout ────────────────────
              Column(
                children: [

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: _buildHeader(),
                  ),

                  // Gold hairline divider
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _border,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search bar
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: DashboardSearchBar(),
                  ),

                  const SizedBox(height: 16),

                  // Grid + footer
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          Expanded(
                            child: DashboardGrid(
                              profiles:         profiles,
                              scrollController: _scrollController,
                            ),
                          ),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
