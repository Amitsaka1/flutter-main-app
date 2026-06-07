import 'package:flutter/material.dart';
import '../../data/models/voice_group_model.dart';

// ─────────────────────────────────────────────────────────
//  VOICE LISTENER BAR
//  Niche ki bar — listener count + mini avatars
//  Tap karo — poori listener list sheet mein khulegi
// ─────────────────────────────────────────────────────────

class VoiceListenerBar extends StatelessWidget {
  final int                    listenerCount;
  final List<VoiceMemberModel> listeners;
  final VoidCallback?          onTap;

  static const _bg     = Color(0xFF0E0E18);
  static const _border = Color(0xFF1E1E2E);
  static const _gold   = Color(0xFFD4A843);
  static const _muted  = Color(0xFF55556A);

  const VoiceListenerBar({
    super.key,
    required this.listenerCount,
    this.listeners = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: listenerCount > 0 ? onTap : null,
      child: Container(
        margin:  const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        _bg,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: _border),
        ),
        child: Row(
          children: [

            // ── Headphone icon ─────────────────────
            const Icon(
              Icons.headphones_rounded,
              size:  16,
              color: _muted,
            ),
            const SizedBox(width: 8),

            // ── Count text ─────────────────────────
            Text(
              "$listenerCount Listener${listenerCount == 1 ? '' : 's'}",
              style: const TextStyle(
                color:      _muted,
                fontSize:   12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            // ── Mini avatars — pehle 5 ─────────────
            if (listeners.isNotEmpty)
              _MiniAvatarRow(
                listeners: listeners.take(5).toList(),
              ),

            // ── Tap hint arrow ─────────────────────
            if (listenerCount > 0) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                size:  16,
                color: _muted,
              ),
            ],

          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MINI AVATAR ROW
//  Pehle 5 listeners ke chhote overlapping avatars
// ─────────────────────────────────────────────────────────

class _MiniAvatarRow extends StatelessWidget {
  final List<VoiceMemberModel> listeners;

  static const _gold    = Color(0xFFD4A843);
  static const _surface = Color(0xFF13131F);
  static const _dark    = Color(0xFF0A0A0F);

  const _MiniAvatarRow({required this.listeners});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width:  (listeners.length * 18.0) + 6,
      child: Stack(
        children: List.generate(listeners.length, (i) {
          final m         = listeners[i];
          final hasAvatar = m.avatarUrl?.isNotEmpty == true;

          return Positioned(
            left: i * 18.0,
            child: Container(
              width:  24,
              height: 24,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(color: _dark, width: 1.5),
              ),
              child: CircleAvatar(
                radius:          12,
                backgroundColor: _surface,
                backgroundImage: hasAvatar
                    ? NetworkImage(m.avatarUrl!)
                    : null,
                child: hasAvatar
                    ? null
                    : Text(
                        (m.name?.isNotEmpty == true)
                            ? m.name![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize:   9,
                          color:      _gold,
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
//  LISTENER SHEET
//  VoiceListenerBar tap hone pe yeh sheet khulegi
//  Saare listeners ki profile — avatar, name, level
// ─────────────────────────────────────────────────────────

class VoiceListenerSheet extends StatelessWidget {
  final List<VoiceMemberModel> listeners;
  final int                    listenerCount;

  static const _bg        = Color(0xFF0E0E18);
  static const _surface   = Color(0xFF13131F);
  static const _border    = Color(0xFF1E1E2E);
  static const _gold      = Color(0xFFD4A843);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _muted     = Color(0xFF55556A);

  const VoiceListenerSheet({
    super.key,
    required this.listeners,
    required this.listenerCount,
  });

  static void show({
    required BuildContext        context,
    required List<VoiceMemberModel> listeners,
    required int                 listenerCount,
  }) {
    showModalBottomSheet(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VoiceListenerSheet(
        listeners:     listeners,
        listenerCount: listenerCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color:        _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Handle ───────────────────────────────
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color:        _border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.headphones_rounded,
                size:  16,
                color: _muted,
              ),
              const SizedBox(width: 8),
              Text(
                "$listenerCount Listener${listenerCount == 1 ? '' : 's'}",
                style: const TextStyle(
                  color:      _textPrime,
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── List ─────────────────────────────────
          listeners.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "No listeners yet",
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                )
              : Flexible(
                  child: ListView.separated(
                    shrinkWrap:    true,
                    itemCount:     listeners.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _ListenerTile(member: listeners[i]),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  LISTENER TILE — Ek listener ki row
// ─────────────────────────────────────────────────────────

class _ListenerTile extends StatelessWidget {
  final VoiceMemberModel member;

  static const _surface   = Color(0xFF13131F);
  static const _border    = Color(0xFF1E1E2E);
  static const _gold      = Color(0xFFD4A843);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _muted     = Color(0xFF55556A);

  const _ListenerTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = member.avatarUrl?.isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: _border),
      ),
      child: Row(
        children: [

          // ── Avatar ───────────────────────────────
          CircleAvatar(
            radius:          20,
            backgroundColor: _border,
            backgroundImage: hasAvatar
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: hasAvatar
                ? null
                : Text(
                    (member.name?.isNotEmpty == true)
                        ? member.name![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color:      _gold,
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // ── Name + Level ─────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name ?? "User",
                  style: const TextStyle(
                    color:      _textPrime,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                ),
                Text(
                  "Lv.${member.level}",
                  style: const TextStyle(
                    color:    _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── Headphone badge ───────────────────────
          const Icon(
            Icons.headphones_rounded,
            size:  14,
            color: _muted,
          ),

        ],
      ),
    );
  }
}
