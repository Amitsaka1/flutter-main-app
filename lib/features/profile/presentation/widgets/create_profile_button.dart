import 'package:flutter/material.dart';

class CreateProfileButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const CreateProfileButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(45),
        backgroundColor: const Color(0xFF0072ff),
      ),
      child: Text(
        loading
            ? "Creating..."
            : "Create Profile",
      ),
    );

    // ================= UI END =================
  }
}
