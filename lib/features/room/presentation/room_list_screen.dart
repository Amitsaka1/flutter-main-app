import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/user_session.dart';
import '../../../core/socket/global_socket_manager.dart';

import '../data/room_api.dart';

import 'widgets/room_tile.dart';
import 'widgets/room_empty.dart';
import 'widgets/room_section_header.dart';
import 'widgets/create_room_dialog.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen>
    with TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _accent    = Color(0xFF6C63FF);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _live      = Color(0xFFE05C5C);
  static const _online    = Color(0xFF39E27A);

  // ── State ─────────────────────────────────────
  bool          _loading   = true;
  List<dynamic> _myRooms   = [];
  List<dynamic> _liveRooms = [];

  StreamSubscription? _socketSub;

  // ── Animations ───────────────────────────────
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late AnimationController _liveCtrl;    // live dot pulse
  late AnimationController _fabCtrl;     // fab entrance

  late Animation<double> _headerFade;
  late Animation<double> _headerSlide;
  late Animation<double> _livePulse;
  late Animation<double> _fabScale;

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
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _headerSlide = Tween<double>(begin: -18, end: 0).animate(
      CurvedAnimation(
        parent: _headerCtrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // List stagger
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Live dot pulse
    _liveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _livePulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _liveCtrl, curve: Curves.easeInOut),
    );

    // FAB entrance
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
    );

    _loadRooms();
    _listenRoomUpdates();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    _liveCtrl.dispose();
    _fabCtrl.dispose();
    _socketSub?.cancel();
    super.dispose();
  }

  // =========================
  // SOCKET
  // =========================

  void _listenRoomUpdates() {
    _socketSub = GlobalSocketManager.instance.messages.listen((event) {
      if (event["type"] == "ROOM_REMOVED") {
        final roomId = event["roomId"];
        if (!mounted) return;
        setState(() {
          _myRooms.removeWhere((room) => room["id"] == roomId);
          _liveRooms.removeWhere((room) => room["id"] == roomId);
        });
      }
    });
  }

  // =========================
  // LOAD ROOMS
  // =========================

  Future<void> _loadRooms() async {
    try {
      final userId  = UserSession.getUserId();
      final myRooms = await RoomApi.getRooms(userId: userId, type: "MY");
      final liveRooms = await RoomApi.getRooms();

      if (!mounted) return;

      setState(() {
        _myRooms   = myRooms;
        _liveRooms = liveRooms;
        _loading   = false;
      });

      _listCtrl..reset()..forward();
      _fabCtrl..reset()..forward();

    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // =========================
  // ENTER ROOM
  // =========================

  Future<void> _enterRoom(Map<String, dynamic> room) async {
    final userId = UserSession.getUserId();
    if (userId == null) return;

    final roomId = room["id"];

    try {
      if (room["status"] == "INACTIVE") {
        await RoomApi.activateRoom(userId: userId, roomId: roomId);
      }

      if (!mounted) return;

      context.push("/room", extra: {"roomId": roomId});

    } catch (e) {
      if (!mounted) return;
      _showErrorToast(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // =========================
  // CREATE ROOM
  // =========================

  void _openCreateRoomDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return CreateRoomDialog(
          nameController: nameController,
          descController: descController,
          onStart: () async {
            final userId = UserSession.getUserId();
            if (userId == null) return;

            try {
              final roomId = await RoomApi.createRoom(
                userId:      userId,
                name:        nameController.text.trim(),
                description: descController.text.trim(),
              );

              await RoomApi.activateRoom(userId: userId, roomId: roomId);

              if (!mounted) return;

              Navigator.pop(context);
              context.push("/room", extra: {"roomId": roomId});

            } catch (e) {
              if (!mounted) return;
              _showErrorToast(e.toString().replaceAll("Exception: ", ""));
            }
          },
        );
      },
    );
  }

  // ── Error toast ───────────────────────────────
  void _showErrorToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation:       0,
        behavior:        SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:        _surfaceHi,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _live.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: _live),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color:    _textPrime,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Per item stagger ──────────────────────────
  Animation<double> _itemAnim(int index) {
    final start = (index / 12 * 0.6).clamp(0.0, 0.75);
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

              // Title block
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [_goldA, _goldB],
                    ).createShader(b),
                    child: const Text(
                      "Rooms",
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
                    "Discover live conversations",
                    style: TextStyle(
                      color:    _textMuted,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Live rooms count pill
              if (_liveRooms.isNotEmpty)
                AnimatedBuilder(
                  animation: _livePulse,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical:   5,
                    ),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color:        _live.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _live.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width:  6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _live,
                            boxShadow: [
                              BoxShadow(
                                color:      _live.withOpacity(
                                  _livePulse.value * 0.8,
                                ),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "${_liveRooms.length} Live",
                          style: const TextStyle(
                            color:      _live,
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Create room button
              GestureDetector(
                onTap: _openCreateRoomDialog,
                child: Container(
                  width:  42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      colors: [_goldC, _goldA],
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:       _goldA.withOpacity(0.35),
                        blurRadius:  14,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size:  20,
                    color: Color(0xFF0A0A0F),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
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

  // ── Loading skeleton ──────────────────────────
  Widget _buildLoadingSkeleton() {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _buildHeader(),
          _buildDivider(),
          const SizedBox(height: 20),
          ...List.generate(5, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical:    6,
              ),
              height: 76,
              decoration: BoxDecoration(
                color:        _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width:  48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _surfaceHi,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width:  120,
                        height: 12,
                        decoration: BoxDecoration(
                          color:        _surfaceHi,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width:  80,
                        height: 10,
                        decoration: BoxDecoration(
                          color:        _surfaceHi,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Staggered tile wrapper ────────────────────
  Widget _staggeredTile(Widget child, int index) {
    final anim = _itemAnim(index);
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Loading skeleton
    if (_loading) return _buildLoadingSkeleton();

    // ===================== UI START =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [

            // ── Top radial glow ─────────────────
            Positioned(
              top:   -40,
              left:  0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _goldA.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

            // ── Main content ───────────────────
            SafeArea(
              child: Column(
                children: [

                  // Header
                  _buildHeader(),

                  // Divider
                  _buildDivider(),

                  const SizedBox(height: 8),

                  // List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh:       _loadRooms,
                      color:           _goldA,
                      backgroundColor: _surface,
                      strokeWidth:     2,
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(
                          top:    8,
                          bottom: 32,
                        ),
                        children: [

                          // ── MY ROOMS ────────────────
                          if (_myRooms.isNotEmpty) ...[

                            _staggeredTile(
                              RoomSectionHeader(title: "My Rooms"),
                              0,
                            ),

                            ..._myRooms.asMap().entries.map((e) {
                              return _staggeredTile(
                                RepaintBoundary(
                                  child: RoomTile(
                                    room:  e.value,
                                    onTap: () => _enterRoom(e.value),
                                  ),
                                ),
                                e.key + 1,
                              );
                            }),

                            const SizedBox(height: 8),

                          ],

                          // ── LIVE ROOMS ───────────────
                          if (_liveRooms.isNotEmpty) ...[

                            _staggeredTile(
                              RoomSectionHeader(title: "🔥 Live Rooms"),
                              _myRooms.length + 1,
                            ),

                            ..._liveRooms.asMap().entries.map((e) {
                              return _staggeredTile(
                                RepaintBoundary(
                                  child: RoomTile(
                                    room:  e.value,
                                    onTap: () => _enterRoom(e.value),
                                  ),
                                ),
                                _myRooms.length + e.key + 2,
                              );
                            }),

                          ],

                          // ── EMPTY ────────────────────
                          if (_myRooms.isEmpty && _liveRooms.isEmpty)
                            const RoomEmpty(),

                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),

          ],
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
