import 'package:flutter/material.dart';

class ProfileFollowButton extends StatelessWidget {

  final bool isFollowing;
  final bool actionLoading;
  final VoidCallback onTap;

  const ProfileFollowButton({
    super.key,
    required this.isFollowing,
    required this.actionLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFollowing
                  ? const Color(0xFF444B57)
                  : const Color(0xFF1C1F26),

          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(30),
          ),
        ),

        onPressed:
            actionLoading ? null : onTap,

        child: actionLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isFollowing
                    ? "Following"
                    : "+ Follow",

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );

    // ================= UI END =================
  }
}
