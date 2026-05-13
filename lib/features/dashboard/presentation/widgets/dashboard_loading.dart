import 'package:flutter/material.dart';

class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    return const Center(
      child: CircularProgressIndicator(),
    );

    // ===================== UI END =======================
  }
}
