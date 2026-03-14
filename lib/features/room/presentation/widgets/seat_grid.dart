import 'package:flutter/material.dart';

class SeatGrid extends StatelessWidget {

  final List seats;
  final Function onSeatTap;

  const SeatGrid({
    super.key,
    required this.seats,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {

        final seat = seats[index];
        final occupied = seat["userId"] != null;

        return GestureDetector(
          onTap: () => onSeatTap(seat),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
      },
    );
  }
}
