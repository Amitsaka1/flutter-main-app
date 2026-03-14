import 'package:flutter/material.dart';

class SeatGrid extends StatelessWidget {

  final List<Map<String, dynamic>> seats;
  final void Function(Map<String, dynamic>) onSeatTap;

  const SeatGrid({
    super.key,
    required this.seats,
    required this.onSeatTap,
  });

  Widget buildSeat(Map seat) {

    final occupied = seat["userId"] != null;

    return GestureDetector(
      onTap: () => onSeatTap(seat),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade800,
            child: occupied
                ? const Icon(Icons.person, color: Colors.white)
                : const Icon(Icons.add, color: Colors.white54),
          ),

          const SizedBox(height: 6),

          Text(
            occupied ? seat["userId"] : "Empty",
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

    if (seats.isEmpty) return const SizedBox();

    return Column(
      children: [

        /// TOP HOST SEAT
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Center(
            child: buildSeat(seats[0]),
          ),
        ),

        /// REST SEATS GRID
        Expanded(
          child: GridView.builder(

            itemCount: seats.length - 1,

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
            ),

            itemBuilder: (context, index) {

              final seat = seats[index + 1];

              return buildSeat(seat);

            },
          ),
        ),

      ],
    );

  }

}
