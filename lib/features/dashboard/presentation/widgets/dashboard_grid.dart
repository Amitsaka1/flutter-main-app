import 'package:flutter/material.dart';

import 'profile_card.dart';

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

    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: profiles.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final p = profiles[index];
        return ProfileCard(profile: p);
      },
    );

    // ===================== UI END =======================
  }
}
