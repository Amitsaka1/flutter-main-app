import 'package:flutter/material.dart';

class SeatGrid extends StatelessWidget {

  final List<Map<String,dynamic>> seats;
  final Function(Map<String,dynamic>) onSeatTap;

  const SeatGrid({
    super.key,
    required this.seats,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {

    return GridView.builder(

      padding: const EdgeInsets.all(16),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:3,
        crossAxisSpacing:20,
        mainAxisSpacing:20,
      ),

      itemCount: seats.length,

      itemBuilder:(context,index){

        final seat = seats[index];
        final occupied = seat["userId"] != null;

        return GestureDetector(

          onTap:()=>onSeatTap(seat),

          child: CircleAvatar(
            radius:35,
            backgroundColor: Colors.grey.shade800,
            child: occupied
                ? const Icon(Icons.person,color: Colors.white)
                : const Icon(Icons.add,color: Colors.white54),
          ),

        );

      },

    );

  }

}
