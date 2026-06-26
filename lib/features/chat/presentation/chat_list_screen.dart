import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/controllers/chat_controller.dart';
import 'package:app_project/core/database/cache_service.dart';
import 'package:app_project/core/data/global_data_manager.dart';

import 'package:app_project/providers/recent_chats_provider.dart';
import 'package:app_project/providers/online_users_provider.dart';

import 'widgets/chat_card.dart';
import 'widgets/chat_list_empty.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  // ── Palette — ✅ UNCHANGED ────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  final ChatController _controller = ChatController.instance;

  // ✅ FIX #1: fallbackChats hata diya — single source of truth
  //
  // Problem: Pehle 2 data sources the — fallbackChats (local state) aur
  //          recentChatsProvider (Riverpod). Screen confuse hoti thi kaunsa
  //          use kare — baar baar loading isliye dikhti thi
  //
  // Fix: Sirf recentChatsProvider use karo — GlobalSocketManager already
  //      isko real-time update karta hai (Fix #1 ke baad)
  //      fallbackChats completely remove kiya
  //
  bool loading = true;

  // ── Search — ✅ UNCHANGED ─────────────────────
  bool   _searchOpen  = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl  = TextEditingController();
  final FocusNode             _searchFocus = FocusNode();

  // ── Animations — ✅ UNCHANGED ─────────────────
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late AnimationController _searchCtrlAnim;

  late Animation<double> _headerFade;
  late Animation<double> _headerSlide;
  late Animation<double> _searchExpand;
  late Animation<double> _searchFade;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // ✅ UNCHANGED: Header entrance animation
    _headerCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve:  const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _headerSlide = Tween<double>(begin: -16, end: 0).animate(
      CurvedAnimation(
        parent: _headerCtrl,
        curve:  const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // ✅ UNCHANGED: List stagger animation
    _listCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );

    // ✅ UNCHANGED: Search dropdown animation
    _searchCtrlAnim = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 320),
    );

    _searchExpand = CurvedAnimation(
      parent: _searchCtrlAnim,
      curve:  Curves.easeOutCubic,
    );

    _searchFade = CurvedAnimation(
      parent: _searchCtrlAnim,
      curve:  const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });

    _initialize();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    _searchCtrlAnim.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===================== LOGIC — FIXED =====================

  Future<void> _initialize() async {

      // ✅ SQLite se cache load karo — sirf jab controller mein data nahi
      if (!_controller.hasData) {
        final cachedChats = await CacheService.instance.getChats();
        if (cachedChats.isNotEmpty && mounted) {
          ref.read(recentChatsProvider.notifier).state = cachedChats;
          setState(() => loading = false);
          _listCtrl..reset()..forward();
        }
      }

      // In-memory cache check
      if (_controller.hasData) {
        ref.read(recentChatsProvider.notifier).state = _controller.chats;
        setState(() => loading = false);
        _listCtrl..reset()..forward();
        if (_controller.isFresh) return;
      }

      final token = await ApiClient.getToken();
      if (token == null) {
        if (mounted) context.go("/login");
        return;
      }

      try {
        final response = await ApiClient.get("/chat/recent");

        if (response["success"] == true) {
          final data = List<dynamic>.from(response["data"]);

          // SQLite save — unawaited rakho taaki UI block na ho
          GlobalDataManager.instance.setChats(data);

          if (mounted) {
            ref.read(recentChatsProvider.notifier).state = data;
            // ✅ FIX: loading check hatao — hamesha UI update karo
            setState(() => loading = false);
            _listCtrl..reset()..forward();
          }
        }
      } catch (_) {
        if (mounted) setState(() => loading = false);
      }
  }

  // ✅ UNCHANGED: Pull-to-refresh
  Future<void> _onRefresh() async {
    await _initialize();
  }

  // ✅ UNCHANGED: Search toggle
  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);

    if (_searchOpen) {
      _searchCtrlAnim.forward();
      Future.delayed(
        const Duration(milliseconds: 200),
        () => _searchFocus.requestFocus(),
      );
    } else {
      _searchCtrlAnim.reverse();
      _searchCtrl.clear();
      _searchFocus.unfocus();
      setState(() => _searchQuery = '');
    }
  }

  // ✅ UNCHANGED: Filter
  List<dynamic> _filterChats(List<dynamic> chats) {
    if (_searchQuery.isEmpty) return chats;
    return chats.where((chat) {
      final name = (chat["user"]?["name"] ?? "").toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  // ===================== LOGIC END =======================

  // ✅ UNCHANGED: Item animation
  Animation<double> _itemAnim(int index) {
    final start = (index / 10 * 0.6).clamp(0.0, 0.7);
    final end   = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _listCtrl,
      curve:  Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  // ✅ UNCHANGED: Header widget
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: AnimatedBuilder(
        animation: _headerSlide,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _headerSlide.value),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [_goldA, _goldB],
                    ).createShader(b),
                    child: const Text(
                      "Messages",
                      style: TextStyle(
                        color:         Colors.white,
                        fontSize:      22,
                        fontWeight:    FontWeight.w800,
                        letterSpacing: 0.3,
                        height:        1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Your conversations",
                    style: TextStyle(
                      color:         _textMuted,
                      fontSize:      11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleSearch,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width:  42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _searchOpen
                        ? _goldA.withOpacity(0.12)
                        : _surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _searchOpen
                          ? _goldA.withOpacity(0.45)
                          : _border,
                      width: 1,
                    ),
                    boxShadow: _searchOpen
                        ? [BoxShadow(
                            color:      _goldA.withOpacity(0.15),
                            blurRadius: 14,
                            spreadRadius: 1,
                          )]
                        : [],
                  ),
                  child: Icon(
                    _searchOpen
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    size:  18,
                    color: _searchOpen ? _goldA : _textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ UNCHANGED: Search dropdown widget
  Widget _buildSearchDropdown() {
    return AnimatedBuilder(
      animation: _searchExpand,
      builder: (_, __) {
        if (_searchCtrlAnim.value == 0) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            heightFactor: _searchExpand.value,
            child: FadeTransition(
              opacity: _searchFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        _goldA.withOpacity(0.5),
                        _goldA.withOpacity(0.2),
                        _goldA.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:        _goldA.withOpacity(0.10),
                        blurRadius:   16,
                        spreadRadius: -1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(1.2),
                  child: Container(
                    decoration: BoxDecoration(
                      color:        _surfaceHi,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size:  18,
                          color: _goldA.withOpacity(0.7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller:  _searchCtrl,
                            focusNode:   _searchFocus,
                            cursorColor: _goldA,
                            cursorWidth: 1.5,
                            style: const TextStyle(
                              color:         _textPrime,
                              fontSize:      14,
                              fontWeight:    FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search by name...",
                              hintStyle: TextStyle(
                                color:    _textMuted,
                                fontSize: 13.5,
                              ),
                              border:         InputBorder.none,
                              isDense:        true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _searchFocus.requestFocus();
                            },
                            child: Container(
                              width:  20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _textMuted.withOpacity(0.2),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size:  12,
                                color: _textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ UNCHANGED: Divider widget
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _goldA.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ✅ FIX #1: Sirf recentChatsProvider — single source of truth
    // fallbackChats remove kar diya — dual source confusion khatam
    // GlobalSocketManager real-time mein isko update karta hai (Fix #1)
    final allChats    = ref.watch(recentChatsProvider);
    final onlineUsers = ref.watch(onlineUsersProvider);
    final displayChats = _filterChats(allChats);

    // ── Loading / Empty ───────────────────────
    if (loading && allChats.isEmpty) {
      return const ChatListEmpty(loading: true);
    }

    if (allChats.isEmpty) {
      return const ChatListEmpty(loading: false);
    }

    // ===================== UI — ✅ UNCHANGED =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: _bg,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchDropdown(),
              _buildDivider(),
              const SizedBox(height: 8),
              Expanded(
                child: displayChats.isEmpty && _searchQuery.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size:  40,
                              color: _textMuted.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No chats found for\n\"$_searchQuery\"",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:    _textMuted,
                                fontSize: 13,
                                height:   1.6,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh:       _onRefresh,
                        color:           _goldA,
                        backgroundColor: _surface,
                        strokeWidth:     2,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 24),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: displayChats.length,
                          itemBuilder: (context, index) {
                            final chat = displayChats[index];
                            final anim = _itemAnim(index);

                            return AnimatedBuilder(
                              animation: anim,
                              builder: (_, child) => Opacity(
                                opacity: anim.value.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - anim.value)),
                                  child: child,
                                ),
                              ),
                              child: RepaintBoundary(
                                child: ChatCard(
                                  chat:     chat,
                                  isOnline: onlineUsers.contains(
                                    chat["user"]["id"],
                                  ),
                                  onTap: () {
                                    final userId   = chat["user"]["id"];
                                    final name     = chat["user"]["name"]      ?? chat["user"]["phone"] ?? "";
                                    final avatar   = chat["user"]["avatarUrl"] ?? "";
                                    final lastSeen = chat["user"]["lastSeen"];

                                    context.push(
                                      "/chat/$userId",
                                      extra: {
                                        "name":     name,
                                        "avatar":   avatar,
                                        "lastSeen": lastSeen,
                                        "isOnline": onlineUsers.contains(userId),
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
