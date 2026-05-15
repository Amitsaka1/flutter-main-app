import 'package:flutter/material.dart';

class ProfileDetailsAvatar extends StatelessWidget {
  final String? avatar;
  final bool isOnline;

  const ProfileDetailsAvatar({
    super.key,
    required this.avatar,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 3,
              color: const Color(0xFF2E8BFF),
            ),
          ),
        ),

        CircleAvatar(
          radius: 70,
          backgroundImage: avatar != null
              ? NetworkImage(avatar!)
              : const AssetImage(
                  "assets/profile_placeholder.png",
                ) as ImageProvider,
        ),

        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 3,
              ),
            ),
          ),
        ),
      ],
    );

    // ================= UI END =================
  }
}
