import 'package:flutter/material.dart';

import '../../data/models/voice_group_model.dart';

// ─────────────────────────────────────────────────────────
//  VOICE GROUP CARD
//  Path: lib/features/voice_world/presentation/widgets/voice_group_card.dart
//  Grid mein dikhne wala ek group card
// ─────────────────────────────────────────────────────────

class VoiceGroupCard extends StatefulWidget {
  final VoiceGroupModel group;
  final VoidCallback    onJoin;

  const VoiceGroupCard({
    super.key,
    required this.group,
    required this.onJoin,
  });

  @override
  State<VoiceGroupCard> createState() => _VoiceGroupCardState();
}

class _VoiceGroupCardState extends State<VoiceGroupCard>
    with SingleTickerProviderStateMixin {

  static const _surface   = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  late AnimationController _pressCtrl;
  late Animation<double>   _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group  = widget.group;
    final isFull = group.isSpeakerFull;

    return AnimatedBuilder(
      animation: _pressScale,
      builder: (_, child) => Transform.scale(
        scale: _pressScale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown:   (_) => _pressCtrl.forward(),
        onTapUp:     (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color:        _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFull
                  ? Colors.red.withOpacity(0.25)
                  : _goldA.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:       isFull
                    ? Colors.red.withOpacity(0.05)
                    : _goldA.withOpacity(0.05),
                blurRadius:  12,
                spreadRadius: 0,
                offset:      const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Emoji + shortId row ───────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  _ShortIdBadge(shortId: group.shortId),
                ],
              ),

              const SizedBox(height: 8),

              // ── Group name ───────────────────────
              Text(
                group.name,
                style: const TextStyle(
                  color:       _textPrime,
                  fontSize:    14,
                  fontWeight:  FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // ── Speaker + Listener count ─────────
              _CountRow(group: group),

              const Spacer(),

              // ── Member avatars ───────────────────
              _MembersRow(members: group.speakers),

              const SizedBox(height: 10),

              // ── Join / Full button ───────────────
              _JoinButton(
                isFull:  isFull,
                onJoin:  widget.onJoin,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SHORT ID BADGE
// ─────────────────────────────────────────────────────────

class _ShortIdBadge extends StatelessWidget {
  final String shortId;
  const _ShortIdBadge({required this.shortId});

  static const _goldA = Color(0xFFD4A843);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color:        _goldA.withOpacity(0.08),
        border: Border.all(
          color: _goldA.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        "#$shortId",
        style: TextStyle(
          color:       _goldA,
          fontSize:    10,
          fontWeight:  FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  COUNT ROW — Speaker + Listener counts
// ─────────────────────────────────────────────────────────

class _CountRow extends StatelessWidget {
  final VoiceGroupModel group;
  const _CountRow({required this.group});

  static const _textMuted = Color(0xFF55556A);
  static const _goldA     = Color(0xFFD4A843);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        // Speakers
        Icon(
          Icons.mic_rounded,
          size:  12,
          color: group.isSpeakerFull
              ? Colors.red.withOpacity(0.7)
              : _goldA.withOpacity(0.7),
        ),
        const SizedBox(width: 3),
        Text(
          "${group.speakerCount}/${group.maxSpeakers}",
          style: TextStyle(
            color:    group.isSpeakerFull
                ? Colors.red.withOpacity(0.7)
                : _textMuted,
            fontSize: 11,
          ),
        ),

        const SizedBox(width: 10),

        // Listeners
        Icon(
          Icons.headphones_rounded,
          size:  12,
          color: _textMuted,
        ),
        const SizedBox(width: 3),
        Text(
          "${group.listenerCount}",
          style: TextStyle(
            color:    _textMuted,
            fontSize: 11,
          ),
        ),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MEMBERS ROW — Avatar stack
// ─────────────────────────────────────────────────────────

class _MembersRow extends StatelessWidget {
  final List<VoiceMemberModel> members;
  const _MembersRow({required this.members});

  static const _goldA   = Color(0xFFD4A843);
  static const _surface = Color(0xFF0A0A0F);

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox(height: 20);
    }

    final show = members.take(5).toList();

    return SizedBox(
      height: 22,
      child: Stack(
        children: List.generate(show.length, (i) {
          final m       = show[i];
          final hasAvatar = m.avatarUrl != null &&
              m.avatarUrl!.isNotEmpty;

          return Positioned(
            left: i * 16.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _surface, width: 1.5),
              ),
              child: CircleAvatar(
                radius:          10,
                backgroundColor: _goldA.withOpacity(0.3),
                backgroundImage: hasAvatar
                    ? NetworkImage(m.avatarUrl!)
                    : null,
                child: hasAvatar
                    ? null
                    : Text(
                        (m.name?.isNotEmpty == true)
                            ? m.name![0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                          fontSize:   8,
                          color:      Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  JOIN BUTTON
// ─────────────────────────────────────────────────────────

class _JoinButton extends StatelessWidget {
  final bool         isFull;
  final VoidCallback onJoin;

  const _JoinButton({
    required this.isFull,
    required this.onJoin,
  });

  static const _goldA = Color(0xFFD4A843);
  static const _goldB = Color(0xFFE8C86A);

  @override
  Widget build(BuildContext context) {
    if (isFull) {
      // Full — listener join option
      return GestureDetector(
        onTap: onJoin,
        child: Container(
          width:  double.infinity,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color:        Colors.red.withOpacity(0.08),
            border: Border.all(
              color: Colors.red.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.headphones_rounded,
                size:  13,
                color: Colors.red.withOpacity(0.6),
              ),
              const SizedBox(width: 5),
              Text(
                "Listen Only",
                style: TextStyle(
                  color:       Colors.red.withOpacity(0.7),
                  fontSize:    12,
                  fontWeight:  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Speaker join
    return GestureDetector(
      onTap: onJoin,
      child: Container(
        width:  double.infinity,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: const LinearGradient(
            colors: [_goldA, _goldB],
            begin:  Alignment.centerLeft,
            end:    Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color:       _goldA.withOpacity(0.3),
              blurRadius:  8,
              spreadRadius: 0,
              offset:      const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.mic_rounded,
              size:  13,
              color: Color(0xFF0A0A0F),
            ),
            SizedBox(width: 5),
            Text(
              "Join",
              style: TextStyle(
                color:       Color(0xFF0A0A0F),
                fontSize:    13,
                fontWeight:  FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
