import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
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
    with AutomaticKeepAliveClientMixin {

  // 🔥 GLOBAL CACHE
  static Map<String, dynamic>? _cache;

  Map<String, dynamic>? profile;

  bool loading = true;

  StreamSubscription? _socketSub;

  final ImagePicker _picker = ImagePicker();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 🔥 INSTANT LOAD
    if (_cache != null) {
      profile = Map.from(_cache!);
      loading = false;
    }

    _fetchProfile();

    _socketSub =
        GlobalSocketManager.instance.messages.listen((data) {

      if (data["type"] == "WALLET_UPDATED") {

        final newBalance = data["balance"];

        if (!mounted || profile == null) return;

        setState(() {
          profile!["user"]["wallet"] =
              newBalance;
        });

        _cache = Map.from(profile!);
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  // ================= IMAGE =================

  Future<void> _pickImage() async {

    final XFile? image =
        await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    try {

      final file = File(image.path);

      final response =
          await ApiClient.multipart(
        "/profile/upload-avatar",
        file,
        fieldName: "file",
      );

      if (response["success"] == true) {

        final imageUrl =
            response["avatarUrl"];

        setState(() {
          profile!["avatarUrl"] =
              imageUrl;
        });

        _cache = Map.from(profile!);

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Profile updated ✅",
            ),
          ),
        );
      }

    } catch (e) {
      print("Upload error: $e");
    }
  }

  // ================= FETCH =================

  Future<void> _fetchProfile() async {

    try {

      final response =
          await ApiClient.get(
        "/profile/me",
      );

      if (!mounted) return;

      if (response["success"] == true) {

        _cache = response["data"];

        setState(() {
          profile = response["data"];
          loading = false;
        });

      } else {

        setState(() {
          loading = false;
        });
      }

    } catch (_) {

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    super.build(context);

    if (loading && profile == null) {
      return const ProfileLoading();
    }

    if (profile == null) {
      return const ProfileNotFound();
    }

    final user       = profile!["user"];

    final avatar     = profile!["avatarUrl"];

    final name       = profile!["name"] ?? "";

    final username   = profile!["username"] ?? "";

    final followers  = profile!["followers"] ?? 0;

    final following  = profile!["following"] ?? 0;

    final level      = user?["level"] ?? 1;

    final wallet     = user?["wallet"] ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),

        child: Column(
          children: [

            // ================= UI START =================

            ProfileAvatarSection(
              avatar: avatar,
              level: level,
              onPickImage: _pickImage,
            ),

            const SizedBox(height: 15),

            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            Text(
              "@$username",
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [

                ProfileStatBox(
                  title: "Following",
                  value: following,
                ),

                ProfileStatBox(
                  title: "Followers",
                  value: followers,
                ),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              children: [

                ProfileEditButton(
                  onTap: () async {

                    final result =
                        await context.push<bool>(
                      "/edit-profile",
                      extra: profile,
                    );

                    if (result == true) {
                      _fetchProfile();
                    }
                  },
                ),

                const SizedBox(width: 12),

                ProfileWalletCard(
                  wallet: wallet,
                ),
              ],
            ),

            const SizedBox(height: 60),

            // ================= UI END =================
          ],
        ),
      ),
    );
  }
}
