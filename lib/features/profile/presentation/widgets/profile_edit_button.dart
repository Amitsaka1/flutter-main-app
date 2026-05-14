import 'package:flutter/material.dart';

class ProfileEditButton extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileEditButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C1F26),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        icon: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
        label: const Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // ================= UI END =================
  }
}
