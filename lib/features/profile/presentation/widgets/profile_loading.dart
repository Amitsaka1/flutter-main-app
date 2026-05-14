import 'package:flutter/material.dart';

class ProfileLoading extends StatelessWidget {
  const ProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return const Center(
      child: CircularProgressIndicator(),
    );

    // ================= UI END =================
  }
}
