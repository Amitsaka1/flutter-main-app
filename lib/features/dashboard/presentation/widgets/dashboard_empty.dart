import 'package:flutter/material.dart';

class DashboardEmpty extends StatelessWidget {
  const DashboardEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return const Center(
      child: Text("No profiles found"),
    );

    // ===================== UI END =======================
  }
}
