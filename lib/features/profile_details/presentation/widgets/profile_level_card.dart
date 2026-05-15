import 'package:flutter/material.dart';

class ProfileLevelCard extends StatelessWidget {

  final int level;
  final int xp;
  final double progress;

  const ProfileLevelCard({
    super.key,
    required this.level,
    required this.xp,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const Icon(
                Icons.star,
                color: Colors.amber,
              ),

              const SizedBox(width: 8),

              Text(
                "Level $level",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation(
                Color(0xFF2E8BFF),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "$xp XP",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
