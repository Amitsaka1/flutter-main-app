import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:app_project/core/controllers/nearby_controller.dart';
import 'package:app_project/core/location/nearby_service.dart';
import 'package:app_project/core/session/user_session.dart';
import 'package:app_project/core/socket/global_socket_manager.dart';
import 'package:app_project/shared/widgets/radius_picker_dialog.dart';

// Same obsidian-dark tokens as chat_conversation_screen.dart — kept
// consistent, jaisa design kiya tha ("UI bilkul waisa hi dikhega jaisa
// Momo ki 1-1 chat screen dikhti hai").
abstract final class _C {
  static const bg      = Color(0xFF07090F);
  static const surface = Color(0xFF0D1117);
  static const card    = Color(0xFF141B27);
  static const bubble  = Color(0xFF172032);

  static const a1 = Color(0xFF5E5CE6);
  static const a2 = Color(0xFF32D9C8);
  static const a3 = Color(0xFF7B61FF);

  static const white   = Color(0xFFEAEEF8);
  static const muted   = Color(0xFF8A99B3);
  static const hint    = Color(0xFF3E4F68);
  static const divider = Color(0xFF151E2E);
  static const gold    = Color(0xFFD4A843);

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
}

class NearbyGroupChatScreen extends StatefulWidget {
  const NearbyGroupChatScreen({super.key});

  @override
  State<NearbyGroupChatScreen> createState() => _NearbyGroupChatScreenState();
}

class _NearbyGroupChatScreenState extends State<NearbyGroupChatScreen> {
  final _controller = NearbyController.instance;
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  StreamSubscription? _socketSub;
  bool _isTyping = false;
  bool _sending = false;
  bool _radiusBusy = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(_onTextChanged);
    _controller.addListener(_onControllerChanged);

    // Live feed subscribe -- sirf jab tak ye screen khuli hai (design ke
    // mutabik: persistent membership nahi hai, channels sirf yahan attach).
    GlobalSocketManager.instance.subscribeToNearby(_controller.channels);

    _socketSub = GlobalSocketManager.instance.messages.listen((event) {
      if (event["type"] != "NEARBY_MESSAGE") return;
      final data = event["data"] as Map<String, dynamic>?;
      if (data == null) return;

      // Apna hi bheja message Centrifugo se echo hoke wapas aata hai
      // (apna geohash-cell apne hi subscribed channels me hota hai) --
      // usko _sendMessage() ke response se already replace kar chuke
      // hain, isliye yaha dobara add nahi karna (warna duplicate bubble
      // ban jayega).
      if (data["senderId"]?.toString() == UserSession.userId) return;

      _controller.addIncomingMessage(data);
      _scrollToBottom();
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    final hasText = _textCtrl.text.trim().isNotEmpty;
    if (hasText == _isTyping) return;
    setState(() => _isTyping = hasText);
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Screen se bahar niklo -- live feed se disconnect (jaisa design kiya
    // tha, koi persistent membership nahi hai).
    GlobalSocketManager.instance.unsubscribeFromNearby();
    _socketSub?.cancel();
    _controller.removeListener(_onControllerChanged);
    _textCtrl.removeListener(_onTextChanged);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Change radius (inside chat, jaisa design kiya tha) ─────────────

  Future<void> _changeRadius() async {
    final newRadius = await showRadiusPickerDialog(
      context,
      initialRadiusKm: _controller.radiusKm,
      initialLocationEnabled: _controller.locationEnabled,
      onRequestLocation: () async {
        final result = await _controller.updateMyLocation();
        return result == NearbyLocationResult.success;
      },
      confirmLabel: "Update",
    );
    if (newRadius == null || !mounted) return;

    setState(() => _radiusBusy = true);
    final result = await _controller.findWithRadius(newRadius);
    if (!mounted) return;
    setState(() => _radiusBusy = false);

    if (result == NearbyLocationResult.success) {
      // Naye channels pe re-subscribe -- purane khud-b-khud unsubscribe ho
      // jate hain (CentrifugoService isi tarah likha hai).
      await GlobalSocketManager.instance.subscribeToNearby(_controller.channels);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group updated successfully")),
      );
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_locationErrorMessage(result))),
      );
    }
  }

  String _locationErrorMessage(NearbyLocationResult result) {
    switch (result) {
      case NearbyLocationResult.gpsOff:
        return "GPS on karke dobara try karo";
      case NearbyLocationResult.permissionDenied:
        return "Location permission chahiye";
      case NearbyLocationResult.permissionPermanentlyDenied:
        return "Settings me jaake location permission on karo";
      case NearbyLocationResult.locationUnavailable:
        return "Location nahi mil paayi, dobara try karo";
      default:
        return "Kuch galat ho gaya, dobara try karo";
    }
  }

  // ── Send message ────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempMsg = {
      "id": tempId,
      "senderId": UserSession.userId,
      "senderName": UserSession.name ?? "You",
      "senderAvatarUrl": UserSession.avatarUrl,
      "text": text,
      "createdAt": DateTime.now().toIso8601String(),
    };

    setState(() => _sending = true);
    _controller.addIncomingMessage(tempMsg); // optimistic UI
    _textCtrl.clear();
    _scrollToBottom();

    try {
      final realData = await NearbyService.send(
        text: text,
        radiusKm: _controller.radiusKm,
      );
      // Optimistic tempId ko server ke real id/data se replace karo --
      // taaki Centrifugo echo aane pe duplicate na bane.
      _controller.replaceMessage(tempId, realData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Message bhej nahi paya, dobara try karo")),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: _controller.messages.isEmpty
                  ? _buildEmptyState()
                  : _buildList(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: _C.avatarGrad,
            ),
            child: const Icon(Icons.groups_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Official Group",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: _radiusBusy ? null : _changeRadius,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 11, color: _C.gold),
                    const SizedBox(width: 2),
                    Text(
                      _radiusBusy
                          ? "Updating…"
                          : "${_fmtKm(_controller.radiusKm)}  ·  change",
                      style: const TextStyle(color: _C.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtKm(double km) {
    if (km < 1) return "${(km * 1000).round()} m";
    return km == km.roundToDouble()
        ? "${km.toStringAsFixed(0)} km"
        : "${km.toStringAsFixed(1)} km";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, color: _C.hint, size: 40),
          const SizedBox(height: 10),
          Text(
            "Abhi koi message nahi hai\nIs radius me sabse pehle tum bolo",
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final msgs = _controller.messages;
    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: msgs.length,
      itemBuilder: (context, index) {
        final reversed = msgs.length - 1 - index;
        final msg = msgs[reversed];
        final isMe = msg["senderId"] == UserSession.userId;
        return _bubble(msg, isMe);
      },
    );
  }

  Widget _bubble(Map<String, dynamic> msg, bool isMe) {
    final text = msg["text"]?.toString() ?? "";
    final senderName = msg["senderName"]?.toString() ?? "Someone";
    final senderAvatar = msg["senderAvatarUrl"]?.toString();
    final distance = msg["distance"]?.toString();
    final senderId = msg["senderId"]?.toString();

    return Padding(
      padding: EdgeInsets.only(
        top: 3,
        bottom: 3,
        left: isMe ? 50 : 0,
        right: isMe ? 0 : 50,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: senderId == null ? null : () => context.push("/profile/$senderId"),
              child: _avatar(senderAvatar, 30),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      senderName,
                      style: const TextStyle(color: _C.muted, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: isMe ? _C.sentGrad : null,
                    color: isMe ? null : _C.bubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe ? _C.a3.withOpacity(0.25) : Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : _C.white.withOpacity(0.92),
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),
                if (!isMe && distance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _C.divider, width: 0.6),
                      ),
                      child: Text(
                        // ✅ Ab sender ka khud-chuna radius nahi -- real
                        // calculated distance (mutual-range se, backend se
                        // aata hai, sirf formatted string -- kabhi raw
                        // coordinates nahi).
                        distance,
                        style: const TextStyle(color: _C.hint, fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? url, double size) {
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _C.avatarGrad),
        child: Icon(Icons.person_rounded, size: size * 0.55, color: Colors.white),
      );
    }
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _C.avatarGrad),
          child: Icon(Icons.person_rounded, size: size * 0.55, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.divider, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 46, maxHeight: 130),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isTyping ? _C.a1.withOpacity(0.6) : _C.divider,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _textCtrl,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 6,
                  style: const TextStyle(color: _C.white, fontSize: 14.5, height: 1.45),
                  decoration: const InputDecoration(
                    hintText: "Type a message…",
                    hintStyle: TextStyle(color: _C.hint, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  cursorColor: _C.a2,
                ),
              ),
            ),
            const SizedBox(width: 9),
            GestureDetector(
              onTap: (_isTyping && !_sending) ? _sendMessage : null,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: _isTyping ? const LinearGradient(colors: [_C.a3, _C.a2]) : null,
                  color: _isTyping ? null : _C.card,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _isTyping ? Colors.transparent : _C.divider, width: 0.8),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isTyping ? Colors.white : _C.muted,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
