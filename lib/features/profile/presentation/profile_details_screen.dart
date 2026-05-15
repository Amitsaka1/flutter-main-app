import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import 'package:app_project/providers/online_users_provider.dart';

import 'widgets/profile_details_avatar.dart';
import 'widgets/profile_pill_stat.dart';
import 'widgets/profile_xp_card.dart';
import 'widgets/profile_follow_button.dart';
import 'widgets/profile_message_button.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileDetailsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState
    extends ConsumerState<ProfileDetailsScreen>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _accent    = Color(0xFF6C63FF);

  // ── Cache (logic unchanged) ──────────────────
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  Map<String, dynamic>? profile;
  bool loading       = true;
  bool actionLoading = false;

  // ── Entrance animation ───────────────────────
  late AnimationController _entranceCtrl;
  late Animation<double>   _fadeIn;
  late Animation<double>   _slideUp;
  late Animation<double>   _heroScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _heroScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fetchProfile();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ===================== LOGIC START =====================

  Future<void> _fetchProfile() async {
    // 🔥 CACHE HIT (INSTANT OPEN)
    if (_profileCache.containsKey(widget.userId)) {
      profile = _profileCache[widget.userId];
      loading = false;
      if (mounted) {
        setState(() {});
        _entranceCtrl.forward();
      }
      // 🔥 continue background refresh
    }

    try {
      final response = await ApiClient.get(
        "/profile/user/${widget.userId}",
      );

      if (!mounted) return;

      if (response["success"] == true && response["data"] != null) {
        profile = response["data"];

        // 🔥 SAVE CACHE
        _profileCache[widget.userId] = profile!;

        setState(() => loading = false);
        if (!_entranceCtrl.isCompleted) {
          _entranceCtrl.forward();
        }
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (profile == null || actionLoading) return;

    final bool isFollowing = profile!["isFollowing"] ?? false;
    setState(() => actionLoading = true);

    try {
      if (isFollowing) {
        await ApiClient.post("/profile/unfollow/${widget.userId}", {});
      } else {
        await ApiClient.post("/profile/follow/${widget.userId}", {});
      }

      if (!mounted) return;

      final currentFollowers = profile!["followers"] ?? 0;

      setState(() {
        profile!["isFollowing"] = !isFollowing;
        profile!["followers"]   = isFollowing
            ? (currentFollowers > 0 ? currentFollowers - 1 : 0)
            : currentFollowers + 1;
        actionLoading = false;
      });

      // 🔥 UPDATE CACHE
      _profileCache[widget.userId] = profile!;
    } catch (_) {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  // ===================== LOGIC END =======================

  // ─────────────────────────────────────────────
  //  Loading state
  // ─────────────────────────────────────────────
  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_goldA),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Loading profile...",
              style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Error state
  // ─────────────────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _surface,
                border: Border.all(color: _border, width: 1),
              ),
              child: Icon(
                Icons.person_off_rounded,
                size: 28,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Profile not found",
              style: TextStyle(
                color: _textPrime,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "This profile may have been removed",
              style: TextStyle(
                color: _textMuted,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _goldA.withOpacity(0.4),
                    width: 1,
                  ),
                  color: _surface,
                ),
                child: const Text(
                  "Go Back",
                  style: TextStyle(
                    color: _goldA,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Floating back button
  // ─────────────────────────────────────────────
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: _textPrime,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Gold hairline divider
  // ─────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _goldA.withOpacity(0.25),
            Colors.transparent,
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

    if (loading && profile == null) return _buildLoading();
    if (profile == null)           return _buildError();

    // ── Data ─────────────────────────────────────
    final user        = profile!["user"];
    final isOnline    = ref.watch(onlineUsersProvider).contains(widget.userId);
    final name        = profile!["name"]        ?? "";
    final username    = profile!["username"]    ?? name;
    final avatar      = profile!["avatarUrl"];
    final followers   = profile!["followers"]   ?? 0;
    final following   = profile!["following"]   ?? 0;
    final xp          = user?["xp"]             ?? 0;
    final level       = user?["level"]          ?? 1;
    final isFollowing = profile!["isFollowing"] ?? false;
    final progress    = (xp % 100) / 100;
    final chatUserId  = user?["id"]?.toString();

    // ===================== UI START =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [

            // ── Background top glow ───────────────
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _goldA.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

            // ── Main content ──────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: AnimatedBuilder(
                  animation: _slideUp,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: child,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [

                        // ── Top bar ────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildBackButton(),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── HERO — Avatar ──────────────────
                        AnimatedBuilder(
                          animation: _heroScale,
                          builder: (_, child) => Transform.scale(
                            scale: _heroScale.value,
                            child: child,
                          ),
                          child: ProfileDetailsAvatar(
                            avatar: avatar,
                            isOnline: isOnline,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Name ───────────────────────────
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [_textPrime, Color(0xFFD0CCCC)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(b),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              height: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Username ───────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _border,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            "@$username",
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Stats row ──────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: ProfilePillStat(
                                  title: "Following",
                                  value: following.toString(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ProfilePillStat(
                                  title: "Followers",
                                  value: followers.toString(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildDivider(),

                        const SizedBox(height: 24),

                        // ── Action buttons — Follow + Message
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ProfileFollowButton(
                                  isFollowing: isFollowing,
                                  actionLoading: actionLoading,
                                  onTap: _toggleFollow,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ProfileMessageButton(
                                  onTap: () {
                                    if (chatUserId != null &&
                                        chatUserId.isNotEmpty) {
                                      context.push("/chat/$chatUserId");
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        _buildDivider(),

                        const SizedBox(height: 24),

                        // ── XP Card ────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ProfileXpCard(
                            level: level,
                            xp: xp,
                            progress: progress,
                          ),
                        ),

                        const SizedBox(height: 60),

                      ],
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
