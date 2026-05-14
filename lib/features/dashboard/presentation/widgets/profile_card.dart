import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_project/providers/online_users_provider.dart';
import 'online_indicator.dart';

// ─────────────────────────────────────────────
//  PROFILE CARD  —  Premium Dark VIP Edition
//  (Performance Optimized — UI Unchanged)
// ─────────────────────────────────────────────

class ProfileCard extends ConsumerWidget {
  final dynamic profile;

  const ProfileCard({
    super.key,
    required this.profile,
  });

  // ── Palette (all static const) ───────────────
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF2A2A3A);
  static const _pillBg    = Color(0xFF1C1C2A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF7A7A8F);
  static const _online    = Color(0xFF39E27A);

  Widget _pill(String label, IconData icon, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _pillBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor ?? _textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _textMuted,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ===================== UI START =====================

    final onlineUsers = ref.watch(onlineUsersProvider);
    final online      = onlineUsers.contains(profile["userId"]?.toString());
    final String? userId    = profile["userId"]?.toString();
    final String  name      = profile["name"]     ?? "";
    final String  gender    = profile["gender"]   ?? "";
    final String  age       = profile["age"]?.toString() ?? "";
    final String  roleType  = profile["roleType"] ?? "";
    final bool    hasPlace  = profile["havePlace"] == true;
    final String? avatarUrl = profile["avatarUrl"]?.toString();
    final bool    hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (userId != null && userId.isNotEmpty) {
          context.push("/profile/$userId");
        }
      },

      // ── Gradient border shell ─────────────────
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2C2C42),
              Color(0xFF181824),
              Color(0xFF2C2C42),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(1.2),

        // ── Inner card surface ────────────────────
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(19),
            boxShadow: const [
              // ⚡ Single shadow, no spread — GPU friendly
              BoxShadow(
                color: Color(0x0A6C63FF),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),

          child: Stack(
            clipBehavior: Clip.none,
            children: [

              // ── Online badge ───────────────────────
              if (online)
                const Positioned(
                  top: -2,
                  right: -2,
                  child: OnlineIndicator(),
                ),

              // ── Card body ─────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const SizedBox(height: 4),

                  // ── Avatar + gold ring ─────────────
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_goldA, _goldB, _goldC],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _surface,
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF1C1C2A),
                        backgroundImage: hasAvatar
                            ? NetworkImage(avatarUrl!)
                            : const AssetImage(
                                    "assets/profile_placeholder.png")
                                as ImageProvider,
                        child: !hasAvatar && name.isNotEmpty
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: _goldA,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Name ──────────────────────────
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _textPrime,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Gender · Age ──────────────────
                  if (gender.isNotEmpty || age.isNotEmpty)
                    Text(
                      [
                        if (gender.isNotEmpty) gender,
                        if (age.isNotEmpty) age,
                      ].join("  ·  "),
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ── Pills ─────────────────────────
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      if (roleType.isNotEmpty)
                        _pill(
                          roleType,
                          Icons.verified_rounded,
                          iconColor: _goldA,
                        ),
                      _pill(
                        hasPlace ? "Has Place" : "No Place",
                        hasPlace
                            ? Icons.home_rounded
                            : Icons.home_outlined,
                        iconColor: hasPlace ? _online : _textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
