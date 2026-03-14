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
      padding: const EdgeInsets.all(20),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: seats.length,
      itemBuilder: (context, index) {

        final seat = seats[index];
        final occupied = seat["userId"] != null;

        return GestureDetector(
          onTap: () => onSeatTap(seat),
          child: Column(
            children: [

              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade800,
                child: occupied
                    ? const Icon(Icons.person, color: Colors.white)
                    : const Icon(Icons.add, color: Colors.white54),
              ),

              const SizedBox(height: 5),

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
