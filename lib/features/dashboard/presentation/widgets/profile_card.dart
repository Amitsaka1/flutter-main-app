import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_project/providers/online_users_provider.dart';
import 'online_indicator.dart';

// ─────────────────────────────────────────────
//  PROFILE CARD  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileCard extends ConsumerWidget {
  final dynamic profile;

  const ProfileCard({
    super.key,
    required this.profile,
  });

  // ── Brand Palette ────────────────────────────
  static const _bg         = Color(0xFF0A0A0F);
  static const _surface    = Color(0xFF12121A);
  static const _border     = Color(0xFF2A2A3A);
  static const _goldA      = Color(0xFFD4A843);
  static const _goldB      = Color(0xFFB8892E);
  static const _accent     = Color(0xFF6C63FF);
  static const _textPrime  = Color(0xFFF0EDE8);
  static const _textMuted  = Color(0xFF7A7A8F);
  static const _online     = Color(0xFF39E27A);
  static const _pillBg     = Color(0xFF1C1C2A);

  static const _gradientGold = LinearGradient(
    colors: [_goldA, _goldB, Color(0xFFE8C86A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _gradientBorder = LinearGradient(
    colors: [Color(0xFF3A3A55), Color(0xFF1E1E2E), Color(0xFF3A3A55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Helpers ──────────────────────────────────
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
    final String? userId = profile["userId"]?.toString();

    final String name      = profile["name"]     ?? "";
    final String gender    = profile["gender"]   ?? "";
    final String age       = profile["age"]?.toString() ?? "";
    final String roleType  = profile["roleType"] ?? "";
    final bool   hasPlace  = profile["havePlace"] == true;
    final String? avatarUrl = profile["avatarUrl"]?.toString();
    final bool   hasAvatar  = avatarUrl != null && avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (userId != null && userId.isNotEmpty) {
          context.push("/profile/$userId");
        }
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: _CardShell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                // ── Online Glow Badge ────────────────
                if (online)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: _OnlinePulseBadge(),
                  ),

                // ── Card Body ────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const SizedBox(height: 4),

                    // Avatar with gold ring
                    _AvatarRing(
                      hasAvatar: hasAvatar,
                      avatarUrl: avatarUrl,
                      name: name,
                    ),

                    const SizedBox(height: 12),

                    // Name
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

                    // Gender • Age
                    if (gender.isNotEmpty || age.isNotEmpty)
                      Text(
                        [if (gender.isNotEmpty) gender, if (age.isNotEmpty) age]
                            .join("  ·  "),
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Role & Place pills
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
      ),
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Card Shell — gradient border + glass inner
// ─────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C42), Color(0xFF181824), Color(0xFF2C2C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(1.2), // border thickness
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E18),
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Avatar with gradient gold ring
// ─────────────────────────────────────────────

class _AvatarRing extends StatelessWidget {
  final bool hasAvatar;
  final String? avatarUrl;
  final String name;

  const _AvatarRing({
    required this.hasAvatar,
    required this.avatarUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFD4A843), Color(0xFFE8C86A), Color(0xFFB8892E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0E0E18),
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF1C1C2A),
          backgroundImage: hasAvatar
              ? NetworkImage(avatarUrl!)
              : const AssetImage("assets/profile_placeholder.png")
                  as ImageProvider,
          child: !hasAvatar && name.isNotEmpty
              ? Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFD4A843),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Online Pulse Badge
// ─────────────────────────────────────────────

class _OnlinePulseBadge extends StatefulWidget {
  @override
  State<_OnlinePulseBadge> createState() => _OnlinePulseBadgeState();
}

class _OnlinePulseBadgeState extends State<_OnlinePulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);

    _scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = Color(0xFF39E27A);
    const size = 10.0;

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: dot,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot,
              boxShadow: [
                BoxShadow(
                  color: dot.withOpacity(0.55),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
