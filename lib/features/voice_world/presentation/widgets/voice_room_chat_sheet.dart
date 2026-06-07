import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/voice_constants.dart';
import '../../../../providers/voice_world_provider.dart';

class VoiceRoomChatSheet extends ConsumerStatefulWidget {
  const VoiceRoomChatSheet({super.key});

  @override
  ConsumerState<VoiceRoomChatSheet> createState() =>
      _VoiceRoomChatSheetState();
}

class _VoiceRoomChatSheetState
    extends ConsumerState<VoiceRoomChatSheet> {

  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  final TextEditingController _ctrl   = TextEditingController();
  final ScrollController      _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (text.length > VoiceConstants.maxMessageLength) return; // FIX: Max 200 chars

    ref.read(voiceRoomProvider.notifier).sendChatMessage(text);
    _ctrl.clear();

    // fix: Naya message aane pe scroll bottom pe
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      voiceRoomProvider.select((s) => s.chatMessages),
    );

    return Container(
      height:     MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color:        _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [

          // ── Handle bar ───────────────────────────
          const SizedBox(height: 12),
          Container(
            width:  40,
            height: 4,
            decoration: BoxDecoration(
              color:        _border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ── Title ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFD4A843), Color(0xFFE8C86A)],
                  ).createShader(b),
                  child: const Text(
                    "Room Chat",
                    style: TextStyle(
                      color:      Colors.white,
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: _textMuted,
                    size:  20,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            color:  _border,
          ),

          // ── Messages list ────────────────────────
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: _textMuted.withOpacity(0.3),
                          size:  40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No messages yet\nSay something!",
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
                : ListView.builder(
                    controller: _scroll,
                    padding:    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount:  messages.length,
                    itemBuilder: (_, i) =>
                        _MessageTile(msg: messages[i]),
                  ),
          ),

          // ── Input bar ────────────────────────────
          Container(
            color:   _surface,
            padding: EdgeInsets.fromLTRB(
              12, 10, 12,
              MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            child: Row(
              children: [

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:        _surfaceHi,
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(color: _border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller:     _ctrl,
                      style: const TextStyle(
                        color:    _textPrime,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText:  "Type a message...",
                        hintStyle: TextStyle(
                          color:    _textMuted,
                          fontSize: 14,
                        ),
                        border:         InputBorder.none,
                        isDense:        true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        counterText: "", // FIX: Counter hide karo
                      ),
                      onSubmitted:     (_) => _send(),
                      textInputAction: TextInputAction.send,
                      maxLines:  1,
                      maxLength: VoiceConstants.maxMessageLength, // FIX: Max 200 characters
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width:  44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4A843), Color(0xFFE8C86A)],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF0A0A0F),
                      size:  20,
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
}

// ─────────────────────────────────────────────────────────
//  MESSAGE TILE — fix: isMe right, others left
// ─────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final VoiceChatMessage msg;

  static const _goldA     = Color(0xFFD4A843);
  static const _surfaceHi = Color(0xFF13131F);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _border    = Color(0xFF1E1E2E);

  const _MessageTile({required this.msg});

  String _timeText(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = msg.avatarUrl?.isNotEmpty == true;

    final avatar = CircleAvatar(
      radius:          18,
      backgroundColor: _goldA.withOpacity(0.15),
      backgroundImage: hasAvatar
          ? CachedNetworkImageProvider(msg.avatarUrl!)
          : null,
      child: hasAvatar
          ? null
          : Text(
              msg.name.isNotEmpty
                  ? msg.name[0].toUpperCase()
                  : "?",
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   12,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        // fix: isMe → right, others → left
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [

          // fix: Avatar left side pe sirf doosre ka
          if (!msg.isMe) ...[
            avatar,
            const SizedBox(width: 8),
          ],

          // ── Bubble ───────────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [

                // fix: Name sirf doosre ka dikhao
                if (!msg.isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(
                      msg.name,
                      style: TextStyle(
                        color:      _textMuted,
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical:   8,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isMe
                        ? _goldA.withOpacity(0.15)
                        : _surfaceHi,
                    // fix: Bubble corner shape
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(12),
                      topRight:    const Radius.circular(12),
                      bottomLeft:  Radius.circular(msg.isMe ? 12 : 2),
                      bottomRight: Radius.circular(msg.isMe ? 2 : 12),
                    ),
                    border: Border.all(
                      color: msg.isMe
                          ? _goldA.withOpacity(0.3)
                          : _border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    msg.message,
                    style: const TextStyle(
                      color:    _textPrime,
                      fontSize: 13,
                      height:   1.4,
                    ),
                  ),
                ),

                // Time
                const SizedBox(height: 3),
                Text(
                  _timeText(msg.time),
                  style: TextStyle(
                    color:    _textMuted,
                    fontSize: 10,
                  ),
                ),

              ],
            ),
          ),

          // fix: Avatar right side pe sirf apna
          if (msg.isMe) ...[
            const SizedBox(width: 8),
            avatar,
          ],

        ],
      ),
    );
  }
}
