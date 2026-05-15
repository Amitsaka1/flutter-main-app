import 'package:flutter/material.dart';

class ProfileSaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const ProfileSaveButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text("Save Changes"),
      ),
    );

    // ================= UI END =================
  }
}
