import 'package:flutter/material.dart';

class SeatGrid extends StatelessWidget {

  final List<Map<String, dynamic>> seats;
  final void Function(Map<String, dynamic>) onSeatTap;

  const SeatGrid({
    super.key,
    required this.seats,
    required this.onSeatTap,
  });

  Widget buildSeat(Map<String, dynamic> seat) {

  final occupied = seat["userId"] != null;

  return GestureDetector(
    onTap: () => onSeatTap(seat),

    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Stack(
          children: [

            /// AVATAR
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade800,
              child: occupied
                  ? const Icon(Icons.person, color: Colors.white)
                  : const Icon(Icons.add, color: Colors.white54),
            ),

            /// GREEN MIC ICON
            if (occupied)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
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
        )

      ],
    ),
  );
  }

  @override
  Widget build(BuildContext context) {

    if (seats.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [

        /// HOST SEAT (TOP CENTER)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Center(
            child: buildSeat(seats[0]),
          ),
        ),

        /// OTHER SEATS GRID
        Expanded(
          child: GridView.builder(

            itemCount: seats.length - 1,

            padding: const EdgeInsets.symmetric(horizontal: 20),

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),

            itemBuilder: (context, index) {

              final Map<String, dynamic> seat =
                  seats[index + 1] as Map<String, dynamic>;

              return buildSeat(seat);

            },

          ),
        ),

      ],
    );
  }
}
