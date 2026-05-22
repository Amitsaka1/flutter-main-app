import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../data/room_api.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/socket/global_socket_manager.dart';
import '../../../../core/debug/app_debug.dart';
import '../../../../core/livekit/livekit_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/room_ui.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;

  const RoomScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {

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

  // ===================== STATE START =====================

  List<Map<String, dynamic>> seats = [];

  bool loading       = true;
  bool isHost        = false;
  bool leavingRoom   = false;
  bool _roomJoined   = false;

  final TextEditingController chatController = TextEditingController();

  List<String> messages = [];

  bool showChat = false;
  bool showGift = false;

  LiveKitService? _livekit;

  bool _livekitConnected  = false;
  bool _isReconnecting    = false;
  bool _wasInRoom         = false;

  // ===================== STATE END =======================

  // ── Loading animation ────────────────────────
  late AnimationController _loadCtrl;
  late Animation<double>   _ringRotate;
  late Animation<double>   _orbScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Loading animation
    _loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ringRotate = Tween<double>(begin: 0, end: 6.2832).animate(
      CurvedAnimation(parent: _loadCtrl, curve: Curves.linear),
    );

    _orbScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _initRoom();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadCtrl.dispose();
    _livekit?.disconnect();
    chatController.dispose();
    super.dispose();
  }

  // ===================== LOGIC START =====================

  Future<void> requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception("Microphone permission denied");
    }
  }

  Future<void> _initRoom() async {
    if (_roomJoined) return;
    _roomJoined = true;

    if (!kIsWeb) {
      _livekit = LiveKitService();
    }

    try {
      await requestMicPermission();
    } catch (e) {
      if (!mounted) return;
      _showErrorToast("Microphone permission required");
      Navigator.pop(context);
      return;
    }

    final userId = UserSession.getUserId();
    if (userId == null) return;

    // 🔥 SEAT MAP LISTENER
    GlobalSocketManager.instance.onSeatMapUpdate((data) async {
      if (!mounted) return;

      final seatData = data["seats"];
      if (seatData == null || seatData is! List) return;

      final updatedSeats = List<Map<String, dynamic>>.from(seatData);
      final currentUserId = UserSession.getUserId();

      bool hostFlag    = false;
      bool amISpeaker  = false;

      for (final seat in updatedSeats) {
        if (seat["userId"] == currentUserId) {
          if (seat["role"] == "HOST") hostFlag = true;
          if (seat["role"] == "HOST" || seat["role"] == "SPEAKER") {
            amISpeaker = true;
          }
        }
      }

      if (amISpeaker) {
        await _livekit?.enableMic();
      } else {
        await _livekit?.disableMic();
      }

      setState(() {
        seats   = updatedSeats;
        isHost  = hostFlag;
        loading = false;
      });
    });

    // 🔥 JOIN ROOM
    RoomApi.joinRoom(userId: userId, roomId: widget.roomId);
    _wasInRoom = true;

    // 🔥 SOCKET JOIN
    GlobalSocketManager.instance.joinRoom(widget.roomId);

    // 🔥 SEAT MAP FETCH
    Future.delayed(const Duration(milliseconds: 300), () {
      GlobalSocketManager.instance.send({
        "type":   "GET_SEAT_MAP",
        "roomId": widget.roomId,
      });
    });

    // 🔥 LIVEKIT CONNECT
    if (!_livekitConnected) {
      _livekitConnected = true;

      try {
        final currentUserId = UserSession.getUserId();
        if (currentUserId == null) return;

        await _livekit?.connect(
          userId: currentUserId,
          roomId: widget.roomId,
          role:   "listener",
        );

        await _livekit?.disableMic();

        _livekit?.room?.events.listen((event) {
          if (event.runtimeType.toString() == "RoomDisconnectedEvent") {
            AppDebug.log("LiveKit disconnected → reconnecting...");
            _handleReconnect();
          }
        });
      } catch (e) {
        AppDebug.log("LiveKit connect failed: $e");
      }
    }

    // 🔥 ROOM CLOSED
    GlobalSocketManager.instance.onRoomClosed(() {
      if (!mounted) return;

      if (!leavingRoom) {
        leavingRoom = true;
        _leaveRoom();
      }

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });

    // 🔥 FALLBACK
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (loading) setState(() => loading = false);
    });
  }

  void sendMessage() {
    final text = chatController.text.trim();
    if (text.isEmpty) return;
    setState(() => messages.add(text));
    chatController.clear();
  }

  void toggleChat() {
    setState(() {
      showChat = !showChat;
      if (showChat) showGift = false;
    });
  }

  void toggleGift() {
    setState(() {
      showGift = !showGift;
      if (showGift) showChat = false;
    });
  }

  Future<void> _handleReconnect() async {
    if (_isReconnecting || !_wasInRoom) return;
    _isReconnecting = true;

    try {
      final userId = UserSession.getUserId();
      if (userId == null) return;

      RoomApi.joinRoom(userId: userId, roomId: widget.roomId);
      GlobalSocketManager.instance.joinRoom(widget.roomId);

      Future.delayed(const Duration(milliseconds: 300), () {
        GlobalSocketManager.instance.send({
          "type":   "GET_SEAT_MAP",
          "roomId": widget.roomId,
        });
      });

      await _livekit?.disconnect();
      await _livekit?.connect(
        userId: userId,
        roomId: widget.roomId,
        role:   "listener",
      );
    } catch (e) {
      AppDebug.log("Reconnect failed: $e");
    }

    _isReconnecting = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _handleReconnect();
  }

  Future<void> _leaveRoom() async {
    if (leavingRoom) return;
    leavingRoom = true;

    final userId = UserSession.getUserId();
    if (userId == null) return;

    try {
      await RoomApi.leaveRoom(userId: userId, roomId: widget.roomId);
    } catch (_) {}

    GlobalSocketManager.instance.leaveRoom(widget.roomId);
    _livekit?.disconnect();

    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<bool> _onBackPressed() async {
    if (leavingRoom) return false;

    final result = await _showLeaveDialog();

    if (result == "KEEP") return false;

    if (result == "EXIT") {
      _leaveRoom();
      return true;
    }

    return false;
  }

  void _onSeatTap(Map<String, dynamic> seat) async {
    final userId     = UserSession.getUserId();
    if (userId == null) return;

    final seatUserId = seat["userId"];
    final seatIndex  = seat["seatIndex"];

    if (seatIndex == 1 && !isHost) return;
    if (seatUserId != null) return;

    try {
      await RoomApi.requestSpeaker(
        userId:    userId,
        roomId:    widget.roomId,
        seatIndex: seatIndex,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorToast(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ===================== LOGIC END =======================

  // ── Premium leave dialog ──────────────────────
  Future<String?> _showLeaveDialog() {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "leave",
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (_, __, ___) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Material(
              color:        Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  color:        _surfaceHi,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color:       Colors.black.withOpacity(0.4),
                      blurRadius:  40,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color:       _goldA.withOpacity(0.06),
                      blurRadius:  60,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Icon
                    Container(
                      width:  56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _surface,
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        size:  26,
                        color: _goldA.withOpacity(0.8),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Title
                    const Text(
                      "Leave Room?",
                      style: TextStyle(
                        color:         _textPrime,
                        fontSize:      18,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      "Keep the room running or\nexit completely?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:    _textMuted,
                        fontSize: 13,
                        height:   1.5,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Gold divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _goldA.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Buttons row
                    Row(
                      children: [

                        // Keep button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(
                              context, "KEEP",
                            ),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color:        _surface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: _border,
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Keep",
                                  style: TextStyle(
                                    color:      _textMuted,
                                    fontSize:   14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Exit button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(
                              context, "EXIT",
                            ),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                gradient: const LinearGradient(
                                  colors: [_goldC, _goldA, _goldB],
                                  begin:  Alignment.topLeft,
                                  end:    Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:       _goldA.withOpacity(0.35),
                                    blurRadius:  14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Exit",
                                  style: TextStyle(
                                    color:      Color(0xFF0A0A0F),
                                    fontSize:   14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
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
          ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical:   12,
          ),
          decoration: BoxDecoration(
            color:        _surfaceHi,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _live.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:       Colors.black.withOpacity(0.3),
                blurRadius:  20,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size:  16,
                color: _live,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color:    _textPrime,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading screen ────────────────────────────
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _loadCtrl,
          builder: (_, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Orb + ring
                SizedBox(
                  width:  80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // Glow
                      Container(
                        width:  80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:       _goldA.withOpacity(0.12),
                              blurRadius:  40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color:       _accent.withOpacity(0.07),
                              blurRadius:  60,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                      ),

                      // Spinning arc
                      Transform.rotate(
                        angle: _ringRotate.value,
                        child: CustomPaint(
                          size: const Size(72, 72),
                          painter: _ArcRingPainter(
                            colorA: _goldA,
                            colorB: _accent,
                          ),
                        ),
                      ),

                      // Breathing orb
                      Transform.scale(
                        scale: _orbScale.value,
                        child: Container(
                          width:  36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _goldB.withOpacity(0.9),
                                _goldA.withOpacity(0.5),
                                _goldC.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:       _goldA.withOpacity(0.6),
                                blurRadius:  16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Specular
                      Positioned(
                        top:  26,
                        left: 31,
                        child: Container(
                          width:  7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "JOINING ROOM",
                  style: TextStyle(
                    color:         _textMuted,
                    fontSize:      11,
                    fontWeight:    FontWeight.w500,
                    letterSpacing: 2.8,
                  ),
                ),

              ],
            );
          },
        ),
      ),
    );
  }

  // ── Web fallback ──────────────────────────────
  Widget _buildWebFallback() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_goldC, _goldA],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color:       _goldA.withOpacity(0.35),
                    blurRadius:  24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                size:  32,
                color: Color(0xFF0A0A0F),
              ),
            ),

            const SizedBox(height: 20),

            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_goldA, _goldB],
              ).createShader(b),
              child: const Text(
                "Coming Soon",
                style: TextStyle(
                  color:         Colors.white,
                  fontSize:      24,
                  fontWeight:    FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Rooms are available on\nthe mobile app",
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    _textMuted,
                fontSize: 13,
                height:   1.6,
                letterSpacing: 0.3,
              ),
            ),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Web fallback
    if (kIsWeb) return _buildWebFallback();

    // Loading
    if (loading) return _buildLoadingScreen();

    // ===================== UI START =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          backgroundColor: _bg,
          body: RoomUI(
            seats:        seats,
            messages:     messages,
            controller:   chatController,
            onSend:       sendMessage,
            onSeatTap:    _onSeatTap,
            showChat:     showChat,
            onChatToggle: toggleChat,
            showGift:     showGift,
            onGiftToggle: toggleGift,
          ),
        ),
      ),
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Arc Ring Painter
// ─────────────────────────────────────────────

class _ArcRingPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;

  const _ArcRingPainter({required this.colorA, required this.colorB});

  @override
  void paint(Canvas canvas, Size size) {
    import 'dart:math' as math;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect, 0, math.pi * 1.4, false,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap   = StrokeCap.round
        ..shader      = SweepGradient(
          colors: [colorA, colorA.withOpacity(0.0)],
          stops:  const [0.0, 0.7],
        ).createShader(rect),
    );

    canvas.drawArc(
      rect, math.pi, math.pi * 0.8, false,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap   = StrokeCap.round
        ..shader      = SweepGradient(
          colors:     [colorB, colorB.withOpacity(0.0)],
          stops:      const [0.0, 0.5],
          startAngle: math.pi,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
