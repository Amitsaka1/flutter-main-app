import 'package:flutter/material.dart';

class ProfileStatBox extends StatelessWidget {
  final String title;
  final int value;

  const ProfileStatBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [

          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
