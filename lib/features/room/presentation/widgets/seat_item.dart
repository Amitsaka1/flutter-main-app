import 'package:flutter/material.dart';

class SeatItem extends StatelessWidget {

  final Map<String, dynamic> seat;
  final VoidCallback onTap;

  const SeatItem({
    super.key,
    required this.seat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final occupied =
        seat["userId"] != null;

    // ================= UI START =================

    return GestureDetector(
      onTap: onTap,

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [

          Stack(
            children: [

              /// AVATAR
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    Colors.grey.shade800,

                child: occupied
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.add,
                        color: Colors.white54,
                      ),
              ),

              /// MIC ICON
              if (occupied)
                Positioned(
                  right: -2,
                  bottom: -2,

                  child: Container(
                    padding:
                        const EdgeInsets.all(3),

                    decoration:
                        const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.mic,
                      size: 14,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            occupied
                ? (seat["name"] ?? "User")
                : "Empty",

            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
