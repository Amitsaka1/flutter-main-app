import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/user_session.dart';
import '../../../core/socket/global_socket_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';

import 'widgets/profile_avatar_section.dart';
import 'widgets/profile_stat_box.dart';
import 'widgets/profile_wallet_card.dart';
import 'widgets/profile_edit_button.dart';
import 'widgets/profile_loading.dart';
import 'widgets/profile_not_found.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() =>
      _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _accent    = Color(0xFF6C63FF);

  // 🔥 GLOBAL CACHE
  static Map<String, dynamic>? _cache;

  Map<String, dynamic>? profile;
  bool loading = true;

  StreamSubscription? _socketSub;
  final ImagePicker _picker = ImagePicker();

  // ── Entrance animation ───────────────────────
  late AnimationController _entranceCtrl;
  late Animation<double>   _fadeIn;
  late Animation<double>   _slideUp;
  late Animation<double>   _heroScale;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideUp = Tween<double>(begin: 36, end: 0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _heroScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // 🔥 INSTANT LOAD from cache
    if (_cache != null) {
      profile = Map.from(_cache!);
      loading = false;
      _entranceCtrl.forward();
    }

    _fetchProfile();

    // Socket — wallet update
    _socketSub = GlobalSocketManager.instance.messages.listen((data) {
      if (data["type"] == "WALLET_UPDATED") {
        final newBalance = data["balance"];
        if (!mounted || profile == null) return;
        setState(() {
          profile!["user"]["wallet"] = newBalance;
        });
        _cache = Map.from(profile!);
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _socketSub?.cancel();
    super.dispose();
  }

  // ===================== LOGIC START =====================

  // ── Image pick ────────────────────────────────
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;

    try {
      final file     = File(image.path);
      final response = await ApiClient.multipart(
        "/profile/upload-avatar",
        file,
        fieldName: "file",
      );

      if (response["success"] == true) {
        final imageUrl = response["avatarUrl"];
        setState(() => profile!["avatarUrl"] = imageUrl);
        _cache = Map.from(profile!);

        if (mounted) {
          _showToast("Profile photo updated ✦");
        }
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  // ── Fetch profile ─────────────────────────────
  Future<void> _fetchProfile() async {
  try {
    final response = await ApiClient.get("/profile/me");
    if (!mounted) return;

    if (response["success"] == true) {
      _cache = response["data"];

      // ── ADD THESE 3 LINES ──────────────────
      final user        = response["data"]?["user"];
      final userProfile = response["data"]?["profile"];
      UserSession.setProfile(
        name:      userProfile?["name"]      ?? "",
        avatarUrl: userProfile?["avatarUrl"],
        level:     user?["level"]            ?? 1,
      );
      // ───────────────────────────────────────

      setState(() {
        profile = response["data"];
        loading = false;
      });
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

  // ===================== LOGIC END =======================

  // ── Premium toast ─────────────────────────────
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _goldA.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _goldA.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _goldA,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                message,
                style: const TextStyle(
                  color: _textPrime,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gold hairline divider ─────────────────────
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _goldA.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [

          // Title
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_goldA, _goldB],
            ).createShader(b),
            child: const Text(
              "My Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const Spacer(),

          // Settings icon
          GestureDetector(
            onTap: () => context.push("/settings"),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _border, width: 1),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 18,
                color: _textMuted,
              ),
            ),
          ),

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    if (loading && profile == null) return const ProfileLoading();
    if (profile == null)           return const ProfileNotFound();

    // ── Data ──────────────────────────────────────
    final user      = profile!["user"];
    final avatar    = profile!["avatarUrl"];
    final name      = profile!["name"]      ?? "";
    final username  = profile!["username"]  ?? "";
    final followers = profile!["followers"] ?? 0;
    final following = profile!["following"] ?? 0;
    final level     = user?["level"]        ?? 1;
    final wallet    = user?["wallet"]       ?? 0;

    // ===================== UI START =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: _bg,
        child: Stack(
          children: [

            // ── Background top radial glow ──────
            Positioned(
              top: -40,
              left: 0,
              right: 0,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _goldA.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

            // ── Main layout ─────────────────────
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

                        // ── Header ─────────────────────
                        _buildHeader(),

                        const SizedBox(height: 30),

                        // ── HERO — Avatar ──────────────
                        AnimatedBuilder(
                          animation: _heroScale,
                          builder: (_, child) => Transform.scale(
                            scale: _heroScale.value,
                            child: child,
                          ),
                          child: ProfileAvatarSection(
                            avatar: avatar,
                            level: level,
                            onPickImage: _pickImage,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Name ───────────────────────
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
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              height: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Username pill ──────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
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

                        // ── Stats row ──────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: ProfileStatBox(
                                  title: "Following",
                                  value: following,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ProfileStatBox(
                                  title: "Followers",
                                  value: followers,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildDivider(),

                        const SizedBox(height: 24),

                        // ── Edit + Wallet ───────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [

                              Expanded(
                                flex: 3,
                                child: ProfileEditButton(
                                  onTap: () async {
                                    final result = await context.push<bool>(
                                      "/edit-profile",
                                      extra: profile,
                                    );
                                    if (result == true) _fetchProfile();
                                  },
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                flex: 2,
                                child: ProfileWalletCard(
                                  wallet: wallet,
                                ),
                              ),

                            ],
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
