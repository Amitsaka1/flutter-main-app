import 'package:flutter/material.dart';

class ProfileMessageButton extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileMessageButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E8BFF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        child: const Text(
          "Message",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // ================= UI END =================
  }
}
