import 'package:flutter/material.dart';

class ProfileAvatarSection extends StatelessWidget {
  final String? avatar;
  final int level;
  final VoidCallback onPickImage;

  const ProfileAvatarSection({
    super.key,
    required this.avatar,
    required this.level,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Stack(
      alignment: Alignment.center,
      children: [

        CircleAvatar(
          radius: 60,
          backgroundImage: avatar != null
              ? NetworkImage(avatar!)
              : const AssetImage(
                  "assets/profile_placeholder.png",
                ) as ImageProvider,
        ),

        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onPickImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00F5A0),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),

        Positioned(
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Lv $level",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );

    // ================= UI END =================
  }
}
