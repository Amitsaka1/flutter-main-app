import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/controllers/chat_controller.dart';

import 'package:app_project/providers/recent_chats_provider.dart';

import 'widgets/chat_card.dart';
import 'widgets/chat_list_empty.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
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

  List<dynamic> fallbackChats = [];
  bool loading = true;

  // ── Search ───────────────────────────────────
  bool   _searchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode             _searchFocus = FocusNode();

  // ── Animations ───────────────────────────────
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

    // Header entrance
    _headerCtrl = AnimationController(
      vsync: this,
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

    // List stagger
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Search dropdown
    _searchCtrlAnim = AnimationController(
      vsync: this,
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

  // ===================== LOGIC START =====================

  Future<void> _initialize() async {
    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.go("/login");
      return;
    }

    // 🔥 CACHE
    if (_controller.hasData) {
      final cachedChats = List<dynamic>.from(_controller.chats);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(recentChatsProvider.notifier).state = cachedChats;
      });

      setState(() {
        fallbackChats = cachedChats;
        loading       = false;
      });

      _listCtrl..reset()..forward();
    }

    // 🔥 API REFRESH
    try {
      final response = await ApiClient.get("/chat/recent");

      if (response["success"] == true) {
        final data = List<dynamic>.from(response["data"]);

        ref.read(recentChatsProvider.notifier).state = data;

        if (mounted && loading) {
          setState(() => loading = false);
          _listCtrl..reset()..forward();
        }
      }
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    await _initialize();
  }

  // ── Toggle search ─────────────────────────────
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

  // ── Filter chats by name ──────────────────────
  List<dynamic> _filterChats(List<dynamic> chats) {
    if (_searchQuery.isEmpty) return chats;
    return chats.where((chat) {
      final name = (chat["user"]?["name"] ?? "").toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  // ===================== LOGIC END =======================

  // ── Per item stagger ──────────────────────────
  Animation<double> _itemAnim(int index) {
    final start = (index / 10 * 0.6).clamp(0.0, 0.7);
    final end   = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _listCtrl,
      curve:  Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  // ── Header ────────────────────────────────────
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

              // ── Title block ────────────────────
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
                      color:    _textMuted,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Search icon button ─────────────
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
                        ? [
                            BoxShadow(
                              color:      _goldA.withOpacity(0.15),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
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

  // ── Search dropdown ───────────────────────────
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

                    // ── Gradient border ─────────────
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
                        color:      _goldA.withOpacity(0.10),
                        blurRadius: 16,
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

                        // Search icon
                        Icon(
                          Icons.search_rounded,
                          size:  18,
                          color: _goldA.withOpacity(0.7),
                        ),

                        const SizedBox(width: 10),

                        // TextField
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
                              border:        InputBorder.none,
                              isDense:       true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        // Clear button
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

  // ── Gold divider ──────────────────────────────
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

    final providerChats = ref.watch(recentChatsProvider);
    final allChats      = providerChats.isNotEmpty
        ? providerChats
        : fallbackChats;
    final displayChats  = _filterChats(allChats);

    // ── Loading / Empty ───────────────────────
    if (loading && fallbackChats.isEmpty && providerChats.isEmpty) {
      return const ChatListEmpty(loading: true);
    }

    if (providerChats.isEmpty && fallbackChats.isEmpty) {
      return const ChatListEmpty(loading: false);
    }

    // ===================== UI START =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: _bg,
        child: SafeArea(
          child: Column(
            children: [

              // ── Header ─────────────────────────
              _buildHeader(),

              // ── Search dropdown ────────────────
              _buildSearchDropdown(),

              // ── Divider ────────────────────────
              _buildDivider(),

              const SizedBox(height: 8),

              // ── Chat list ──────────────────────
              Expanded(
                child: displayChats.isEmpty && _searchQuery.isNotEmpty

                    // ── No results ─────────────────
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

                    // ── Chat list ──────────────────
                    : RefreshIndicator(
                        onRefresh:       _onRefresh,
                        color:           _goldA,
                        backgroundColor: _surface,
                        strokeWidth:     2,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            top: 6,
                            bottom: 24,
                          ),
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
                                  chat:  chat,
                                  onTap: () {
                                    final userId = chat["user"]["id"];
                                    context.push("/chat/$userId");
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

    // ===================== UI END =======================
  }
}
