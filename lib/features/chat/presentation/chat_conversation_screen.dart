// ============================================================
//  chat_conversation_screen.dart
//  Premium Obsidian Dark Chat UI
//  ✅ All original logic preserved — only UI upgraded
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/controllers/conversation_controller.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/chat/unread_counter_service.dart';
import 'package:app_project/providers/messages_provider.dart';
import 'package:app_project/providers/online_users_provider.dart';
import 'package:app_project/core/session/user_session.dart';
import 'package:app_project/features/call/presentation/call_screen.dart';

// ──────────────────────────────────────────────────────────────
//  DESIGN TOKENS  (single source of truth)
// ──────────────────────────────────────────────────────────────

abstract final class _C {
  // Backgrounds
  static const bg       = Color(0xFF07090F); // deep obsidian
  static const surface  = Color(0xFF0D1117); // appbar / input bar
  static const card     = Color(0xFF141B27); // button fills
  static const bubble   = Color(0xFF172032); // received message

  // Accents  — electric indigo → cyan
  static const a1       = Color(0xFF5E5CE6); // indigo
  static const a2       = Color(0xFF32D9C8); // teal/cyan
  static const a3       = Color(0xFF7B61FF); // violet highlight

  // Text / meta
  static const white    = Color(0xFFEAEEF8);
  static const muted    = Color(0xFF8A99B3);
  static const hint     = Color(0xFF3E4F68);
  static const divider  = Color(0xFF151E2E);
  static const online   = Color(0xFF2ECC87);

  // Gradients
  static const sentGrad = LinearGradient(
    colors: [a3, a2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const avatarGrad = LinearGradient(
    colors: [a1, a2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const heroBarGrad = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF07090F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ──────────────────────────────────────────────────────────────
//  PROFILE IMAGE VIEWER   (WhatsApp-style full-screen)
// ──────────────────────────────────────────────────────────────

class _ProfileImageViewer extends StatefulWidget {
  final String? imageUrl;
  final String userName;

  const _ProfileImageViewer({
    required this.imageUrl,
    required this.userName,
  });

  @override
  State<_ProfileImageViewer> createState() => _ProfileImageViewerState();
}

class _ProfileImageViewerState extends State<_ProfileImageViewer>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Stack(
              fit: StackFit.expand,
              children: [

                // ── Pinch-zoom image ────────────────────────────────────────
                Center(
                  child: Hero(
                    tag: 'avatar::${widget.userName}',
                    child: _buildFullImage(),
                  ),
                ),

                // ── Top gradient scrim ──────────────────────────────────────
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xCC000000), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // ── Bottom gradient scrim ────────────────────────────────────
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xBB000000), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // ── Header row ──────────────────────────────────────────────
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // Back
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(50),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Name
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'Profile Photo',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildFullImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _AvatarPlaceholder(
        size: 200,
        iconSize: 100,
        gradient: _C.avatarGrad,
      );
    }
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.6,
      maxScale: 5.0,
      child: Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          final percent = progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded /
                progress.expectedTotalBytes!
              : null;
          return Center(
            child: CircularProgressIndicator(
              value: percent,
              color: _C.a2,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _AvatarPlaceholder(
          size: 200,
          iconSize: 100,
          gradient: _C.avatarGrad,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  AVATAR PLACEHOLDER  (reusable)
// ──────────────────────────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  final double size;
  final double iconSize;
  final Gradient gradient;

  const _AvatarPlaceholder({
    required this.size,
    required this.iconSize,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white.withOpacity(0.9),
        size: iconSize,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  CHAT CONVERSATION SCREEN  (main)
// ──────────────────────────────────────────────────────────────

class ChatConversationScreen extends ConsumerStatefulWidget {
  final String  chatUserId;
  final String? chatUserName;     // pass from navigation extras
  final String? chatUserPhotoUrl; // pass from navigation extras
  final dynamic chatUserLastSeen;
  final bool    initialIsOnline;

  const ChatConversationScreen({
    super.key,
    required this.chatUserId,
    this.chatUserName,
    this.chatUserPhotoUrl,
    this.chatUserLastSeen,
    this.initialIsOnline = false,
  });

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen>
    with TickerProviderStateMixin {

  // Controllers
  final _scrollCtrl  = ScrollController();
  final _textCtrl    = TextEditingController();
  final _focusNode   = FocusNode();
  final _logic       = ConversationController.instance;
  final _picker      = ImagePicker();

  // Animation controllers
  late final AnimationController _sendAnim;

  // State
  StreamSubscription<dynamic>? _sub;
  List<dynamic> _messages    = [];
  bool          _loading     = true;
  bool          _isTyping    = false;
  String?       _myId;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _sendAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _textCtrl.addListener(_onTextChanged);
    _initChat();
  }

  void _onTextChanged() {
    final hasText = _textCtrl.text.trim().isNotEmpty;
    if (hasText == _isTyping) return;
    setState(() => _isTyping = hasText);
    hasText ? _sendAnim.forward() : _sendAnim.reverse();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _textCtrl.removeListener(_onTextChanged);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _sendAnim.dispose();
    super.dispose();
  }

  // ── Init (original logic — untouched) ──────────────────────

  Future<void> _initChat() async {
    final token = await ApiClient.getToken();
    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }

    _myId = UserSession.userId;
    
    if (_myId == null) return;

    _logic.init(_myId!);

    _sub = _logic.stream(widget.chatUserId).listen((data) {
      if (!mounted) return;
      setState(() {
        _messages = data as List<dynamic>;
        _loading  = false;
      });
      _scrollToBottom();
    });

    await _logic.loadMessages(widget.chatUserId);
    ChatController.instance.markAsRead(widget.chatUserId);
    UnreadCounterService.clearChat(widget.chatUserId);
  }

  // ── Send message (original logic — untouched) ──────────────

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final tempId =
        DateTime.now()
            .millisecondsSinceEpoch
            .toString();

    final notifier = ref.read(messagesProvider.notifier);
    final current =
        Map<String, List<dynamic>>.from(
      notifier.state,
    );
    final prev     = (current[widget.chatUserId] as List<dynamic>?) ?? [];

    current[widget.chatUserId] = [
      ...prev,
      {
        'id': tempId,
        'senderId':   _myId,
        'receiverId': widget.chatUserId,
        'content':    text,
        'isRead':     false,
      },
    ];

    notifier.state = current;
    _textCtrl.clear();

    await _logic.sendMessage(widget.chatUserId, text);
    
    _scrollToBottom();
  }

  // ── Scroll (original logic — untouched) ───────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ── Start call (original logic — untouched) ───────────────

  Future<void> _startCall(String type) async {
    if (_myId == null) return;

    final response = await ApiClient.post('/call/start', {
      'receiverId': widget.chatUserId,
      'type':       type,
    });

    if (!mounted) return;

    if (response['success'] != true) {
      if (response['status'] == 'OFFLINE') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              channelName:   '',
              callType:      type,
              initialStatus: 'OFFLINE',
            ),
          ),
        );
        return;
      }

      String msg = (response['message'] as String?) ?? 'Call failed';
      if (msg == 'Insufficient balance') msg = 'Low balance. Please recharge.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(msg),
          backgroundColor: Colors.redAccent.shade700,
          behavior:        SnackBarBehavior.floating,
          margin:          const EdgeInsets.all(16),
          shape:           RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    final sessionId = response['sessionId'] as String;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName:   sessionId,
          callType:      type,
          initialStatus: 'RINGING',
        ),
      ),
    );
  }

  // ── Gallery (new — clickable) ─────────────────────────────

  Future<void> _openGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    // TODO: wire picked.path into your send-image API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${picked.name}'),
        backgroundColor: _C.a1,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ── Open profile image (WhatsApp style) ──────────────────

  String _formatLastSeen(dynamic lastSeen) {
      if (lastSeen == null) return "Offline";
      try {
        final dt   = DateTime.parse(lastSeen.toString()).toLocal();
        final now  = DateTime.now();
        final diff = now.difference(dt);
        if (diff.inMinutes < 1)  return "just now";
        if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
        if (diff.inHours   < 24) {
          final h = dt.hour.toString().padLeft(2, '0');
          final m = dt.minute.toString().padLeft(2, '0');
          return "last seen $h:$m";
        }
        return "last seen ${diff.inDays}d ago";
      } catch (_) {
        return "Offline";
      }
    }

  void _openProfileViewer() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        transitionDuration:        const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, _) {
          return FadeTransition(
            opacity: animation,
            child: _ProfileImageViewer(
              imageUrl: widget.chatUserPhotoUrl,
              userName: widget.chatUserName ?? 'Chat',
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provMap  = ref.watch(messagesProvider);
        final provMsgs = provMap[widget.chatUserId] ?? [];

        final seen        = <String>{};
        final displayMsgs = <dynamic>[];
        for (final msg in [..._messages, ...provMsgs]) {
          final id = msg["id"]?.toString() ?? "";
          if (id.isNotEmpty && seen.add(id)) displayMsgs.add(msg);
        }

        final onlineUsers = ref.watch(onlineUsersProvider);
        final isOnline    = onlineUsers.contains(widget.chatUserId);
    
    if (_loading && _messages.isEmpty && displayMsgs.isEmpty) {
      return const Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_C.a2),
            strokeWidth: 1.6,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(isOnline: isOnline),
      body: Column(
        children: [
          Expanded(child: _buildList(displayMsgs)),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  APP BAR
  // ──────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar({ required bool isOnline }) {
    final name     = widget.chatUserName     ?? 'Chat';
    final photoUrl = widget.chatUserPhotoUrl;

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          border: Border(
            bottom: BorderSide(color: _C.divider, width: 0.8),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [

                  // Back button
                  _BarBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),

                  const SizedBox(width: 4),

                  // ── Clickable profile avatar ────────────────────────────
                  GestureDetector(
                    onTap: _openProfileViewer,
                    child: Hero(
                      tag: 'avatar::$name',
                      flightShuttleBuilder: (_, anim, __, ___, ____) {
                        return FadeTransition(
                          opacity: anim,
                          child: _buildAvatarWidget(photoUrl, 44),
                        );
                      },
                      child: _buildAvatarWidget(photoUrl, 44),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ── Name + online — also tappable ───────────────────────
                  Expanded(
                    child: GestureDetector(
                      onTap: _openProfileViewer,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _C.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _C.online,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _C.online.withOpacity(0.55),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  color: _C.online,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Voice call
                  _BarBtn(
                    icon: Icons.call_rounded,
                    onTap: () => _startCall('VOICE_CALL'),
                    glowColor: _C.a2,
                  ),

                  const SizedBox(width: 4),

                  // Video call
                  _BarBtn(
                    icon: Icons.videocam_rounded,
                    onTap: () => _startCall('VIDEO_CALL'),
                    glowColor: _C.a1,
                  ),

                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Avatar widget (network image or placeholder, always circular)
  Widget _buildAvatarWidget(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _C.avatarGrad,
        boxShadow: [
          BoxShadow(
            color: _C.a1.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              )
            : const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 22,
              ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  MESSAGE LIST
  // ──────────────────────────────────────────────────────────

  Widget _buildList(List<dynamic> msgs) {
    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: msgs.length,
      itemBuilder: (context, index) {
        final reversed = msgs.length - 1 - index;
        final msg  = msgs[reversed] as Map<dynamic, dynamic>;
        final isMe = msg['senderId'] == _myId;
        final showHeader = reversed == 0;

        return Column(
          children: [
            if (showHeader) _dateDivider('Today'),
            _bubble(msg, isMe),
          ],
        );
      },
    );
  }

  Widget _dateDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.6,
              color: _C.divider,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.divider, width: 0.8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: _C.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.6,
              color: _C.divider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Map<dynamic, dynamic> msg, bool isMe) {
    final content = msg['content']?.toString() ?? '';
    final isRead  = msg['isRead'] == true;

    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left:  isMe ? 60 : 0,
        right: isMe ? 0  : 60,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [

            // ── Bubble ───────────────────────────────────────────────────
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 11,
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                gradient: isMe ? _C.sentGrad : null,
                color:    isMe ? null : _C.bubble,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(20),
                  topRight:    const Radius.circular(20),
                  bottomLeft:  Radius.circular(isMe ? 20 : 5),
                  bottomRight: Radius.circular(isMe ? 5  : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? _C.a3.withOpacity(0.30)
                        : Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : _C.white.withOpacity(0.9),
                  fontSize: 14.5,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // ── Timestamp + read tick ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _msgTime(msg),
                    style: const TextStyle(
                      color: _C.hint,
                      fontSize: 10,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 13,
                      color: isRead ? _C.a2 : _C.hint,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _msgTime(Map<dynamic, dynamic> msg) {

    final raw =
        msg["createdAt"] ??
        msg["timestamp"];

    if (raw == null) {
      return "";
    }

    try {

      final date = DateTime.parse(
        raw.toString(),
      ).toLocal();

      final h =
          date.hour
              .toString()
              .padLeft(2, '0');

      final m =
          date.minute
              .toString()
              .padLeft(2, '0');

      return "$h:$m";

    } catch (_) {

      return "";
    }
  }

  // ──────────────────────────────────────────────────────────
  //  INPUT BAR
  // ──────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(
          top: BorderSide(color: _C.divider, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [

            // ── Gallery button ─────────────────────────────────────────
            _InputAction(
              icon: Icons.image_rounded,
              color: _C.a2,
              onTap: _openGallery,
            ),

            const SizedBox(width: 9),

            // ── Text field ─────────────────────────────────────────────
            Expanded(child: _buildTextField()),

            const SizedBox(width: 9),

            // ── Send / mic button ──────────────────────────────────────
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 46, maxHeight: 130),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isTyping
              ? _C.a1.withOpacity(0.6)
              : _C.divider,
          width: 1.2,
        ),
        boxShadow: _isTyping
            ? [
                BoxShadow(
                  color: _C.a1.withOpacity(0.10),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // Text input
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 6,
              style: const TextStyle(
                color: _C.white,
                fontSize: 14.5,
                height: 1.45,
              ),
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(color: _C.hint, fontSize: 14),
                contentPadding: EdgeInsets.fromLTRB(16, 12, 8, 12),
                border:         InputBorder.none,
                isDense:        true,
              ),
              keyboardType:     TextInputType.multiline,
              textInputAction:  TextInputAction.newline,
              cursorColor:      _C.a2,
              cursorWidth:      1.6,
            ),
          ),

          // Emoji icon (right-inside field)
          Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 13),
            child: GestureDetector(
              onTap: () {
                // TODO: hook emoji picker
              },
              child: const Icon(
                Icons.emoji_emotions_outlined,
                color: _C.hint,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _isTyping ? _sendMessage : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOutBack,
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: _isTyping
              ? const LinearGradient(
                  colors: [_C.a3, _C.a2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isTyping ? null : _C.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _isTyping ? Colors.transparent : _C.divider,
            width: 0.8,
          ),
          boxShadow: _isTyping
              ? [
                  BoxShadow(
                    color: _C.a1.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: RotationTransition(
              turns: Tween<double>(begin: 0.1, end: 0).animate(anim),
              child: child,
            ),
          ),
          child: Icon(
            _isTyping ? Icons.send_rounded : Icons.mic_none_rounded,
            key: ValueKey<bool>(_isTyping),
            color: _isTyping ? Colors.white : _C.muted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  HELPER WIDGETS
// ──────────────────────────────────────────────────────────────

/// AppBar icon button
class _BarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? glowColor;

  const _BarBtn({
    required this.icon,
    required this.onTap,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.divider, width: 0.8),
          boxShadow: glowColor != null
              ? [
                  BoxShadow(
                    color: glowColor!.withOpacity(0.18),
                    blurRadius: 10,
                  ),
                ]
              : const [],
        ),
        child: Icon(icon, color: Colors.white60, size: 18),
      ),
    );
  }
}

/// Input bar action button (gallery, attach, etc.)
class _InputAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _InputAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _C.divider, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 21),
      ),
    );
  }
}
