import 'package:flutter/material.dart';
import 'profile_card.dart';

// ─────────────────────────────────────────────
//  DASHBOARD GRID  —  Premium Dark VIP Edition
//  (Performance Optimized — UI Unchanged)
// ─────────────────────────────────────────────

class DashboardGrid extends StatelessWidget {
  final List<dynamic> profiles;
  final ScrollController scrollController;

  const DashboardGrid({
    super.key,
    required this.profiles,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    if (profiles.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: profiles.length,

      // ⚡ Performance flags
      cacheExtent: 800,                  // off-screen cards pre-render
      addRepaintBoundaries: true,        // sirf changed card repaint ho
      addAutomaticKeepAlives: false,     // invisible cards memory free karo

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),

      itemBuilder: (context, index) {
        // ⚡ RepaintBoundary — scroll pe sirf
        // visible cards repaint hoti hain
        return RepaintBoundary(
          child: ProfileCard(profile: profiles[index]),
        );
      },
    );

    // ===================== UI END =======================
  }
}
