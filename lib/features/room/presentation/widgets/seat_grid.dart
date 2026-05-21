import 'package:flutter/material.dart';

import 'seat_item.dart';

class SeatGrid extends StatelessWidget {

  final List<Map<String, dynamic>> seats;

  final void Function(
    Map<String, dynamic>,
  ) onSeatTap;

  const SeatGrid({
    super.key,
    required this.seats,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {

    if (seats.isEmpty) {
      return const SizedBox();
    }

    // ================= UI START =================

    return Column(
      children: [

        /// HOST SEAT
        Padding(
          padding:
              const EdgeInsets.only(
            bottom: 20,
          ),

          child: Center(
            child: SeatItem(
              seat: seats[0],

              onTap: () =>
                  onSeatTap(
                seats[0],
              ),
            ),
          ),
        ),

        /// OTHER SEATS
        Expanded(
          child: GridView.builder(

            itemCount:
                seats.length - 1,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),

            itemBuilder:
                (context, index) {

              final seat =
                  seats[index + 1];

              return SeatItem(
                seat: seat,

                onTap: () =>
                    onSeatTap(
                  seat,
                ),
              );
            },
          ),
        ),
      ],
    );

    // ================= UI END =================
  }
}
