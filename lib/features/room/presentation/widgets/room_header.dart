import 'package:flutter/material.dart';

class RoomHeader extends StatelessWidget {

  final int seatCount;

  const RoomHeader({
    super.key,
    required this.seatCount,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),

      child: Row(
        children: [

          const Text(
            "Voice Party",

            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),

            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius:
                  BorderRadius.circular(8),
            ),

            child: Text(
              "LIVE $seatCount/12",

              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
