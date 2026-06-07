import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/voice_group_model.dart';

// ─────────────────────────────────────────────────────────
//  VOICE SEAT TILE
//  Path: lib/features/voice_world/presentation/widgets/voice_seat_tile.dart
//  Ek circle seat — filled ya empty
// ─────────────────────────────────────────────────────────

class VoiceSeatTile extends StatefulWidget {
  final VoiceMemberModel? member;      // null = empty seat
  final bool              isSpeaking;  // LiveKit active speaker
  final bool              isLocalMuted;
  final bool              isBiMuted;
  final bool              isMe;
  final VoidCallback?     onLongPress; // Action menu

  const VoiceSeatTile({
    super.key,
    this.member,
    this.isSpeaking    = false,
    this.isLocalMuted  = false,
    this.isBiMuted     = false,
    this.isMe          = false,
    this.onLongPress,
  });

  bool get isEmpty => member == null;

  @override
  State<VoiceSeatTile> createState() => _VoiceSeatTileState();
}

class _VoiceSeatTileState extends State<VoiceSeatTile>
    with SingleTickerProviderStateMixin {

  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _surface   = Color(0xFF13131F);
  static const _border    = Color(0xFF1E1E2E);
  static const _textMuted = Color(0xFF55556A);
  static const _bg        = Color(0xFF0A0A0F);

  late AnimationController _glowCtrl;
  late Animation<double>   _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceSeatTile old) {
    super.didUpdateWidget(old);
    if (widget.isSpeaking && !old.isSpeaking) {
      _glowCtrl.repeat(reverse: true);
    } else if (!widget.isSpeaking && old.isSpeaking) {
      _glowCtrl.stop();
      _glowCtrl.reset();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = constraints.maxWidth;

        return GestureDetector(
          onLongPress: widget.isEmpty ? null : widget.onLongPress,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Circle seat ──────────────────────
              SizedBox(
                width:  size,
                height: size,
                child: widget.isEmpty
                    ? _EmptySeat(size: size)
                    : _FilledSeat(
                        member:     widget.member!,
                        size:       size,
                        isSpeaking: widget.isSpeaking,
                        glowAnim:   _glowAnim,
                        isMe:       widget.isMe,
                        isMuted:    widget.isLocalMuted ||
                                    widget.isBiMuted,
                      ),
              ),

              const SizedBox(height: 5),

              // ── Name below circle ─────────────────
              SizedBox(
                width: size,
                child: widget.isEmpty
                    ? Text(
                        "Empty",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:    _textMuted.withOpacity(0.4),
                          fontSize: size * 0.18,
                        ),
                      )
                    : Column(
                        children: [
                          Text(
                            widget.member!.name ?? "User",
                            textAlign: TextAlign.center,
                            maxLines:  1,
                            overflow:  TextOverflow.ellipsis,
                            style: TextStyle(
                              color:       widget.isMe
                                  ? _goldA
                                  : Colors.white,
                              fontSize:    size * 0.2,
                              fontWeight:  FontWeight.w600,
                            ),
                          ),
                          // Level badge
                          Text(
                            "Lv.${widget.member!.level}",
                            style: TextStyle(
                              color:    _textMuted,
                              fontSize: size * 0.16,
                            ),
                          ),
                        ],
                      ),
              ),

            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  FILLED SEAT
// ─────────────────────────────────────────────────────────

class _FilledSeat extends StatelessWidget {
  final VoiceMemberModel  member;
  final double            size;
  final bool              isSpeaking;
  final Animation<double> glowAnim;
  final bool              isMe;
  final bool              isMuted;

  static const _goldA   = Color(0xFFD4A843);
  static const _surface = Color(0xFF13131F);

  const _FilledSeat({
    required this.member,
    required this.size,
    required this.isSpeaking,
    required this.glowAnim,
    required this.isMe,
    required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = member.avatarUrl?.isNotEmpty == true;

    return AnimatedBuilder(
      animation: glowAnim,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [

            // ── Speaking glow ring ────────────────
            if (isSpeaking)
              Container(
                width:  size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:       _goldA.withOpacity(
                          glowAnim.value * 0.6),
                      blurRadius:  size * 0.3,
                      spreadRadius: size * 0.05,
                    ),
                  ],
                ),
              ),

            // ── Border ring ───────────────────────
            Container(
              width:  size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSpeaking
                      ? _goldA.withOpacity(glowAnim.value)
                      : isMe
                          ? _goldA.withOpacity(0.5)
                          : isMuted
                              ? Colors.red.withOpacity(0.4)
                              : Colors.white.withOpacity(0.1),
                  width: isSpeaking ? 2.5 : 1.5,
                ),
              ),
            ),

            // ── Avatar circle ─────────────────────
            CircleAvatar(
              radius:          size * 0.44,
              backgroundColor: _goldA.withOpacity(0.15),
              backgroundImage: hasAvatar
                  ? CachedNetworkImageProvider(member.avatarUrl!)
                  : null,
              child: hasAvatar
                  ? null
                  : Text(
                      (member.name?.isNotEmpty == true)
                          ? member.name![0].toUpperCase()
                          : "?",
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   size * 0.32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),

            // ── Mic off badge ─────────────────────
            if (isMuted || member.isMuted)
              Positioned(
                right:  0,
                bottom: 0,
                child: Container(
                  width:  size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.85),
                    border: Border.all(
                      color: const Color(0xFF0A0A0F),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.mic_off_rounded,
                    size:  size * 0.17,
                    color: Colors.white,
                  ),
                ),
              ),

          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EMPTY SEAT
// ─────────────────────────────────────────────────────────

class _EmptySeat extends StatelessWidget {
  final double size;
  const _EmptySeat({required this.size});

  static const _border    = Color(0xFF1E1E2E);
  static const _textMuted = Color(0xFF55556A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _border,
          width: 1.5,
          // Dashed effect — custom painter se
        ),
        color: _border.withOpacity(0.2),
      ),
      child: Center(
        child: Icon(
          Icons.add_rounded,
          size:  size * 0.3,
          color: _textMuted.withOpacity(0.4),
        ),
      ),
    );
  }
}
