import 'package:flutter/material.dart';
import 'seat_grid.dart';
import 'chat_panel.dart';
import 'bottom_controls.dart';

class RoomUI extends StatelessWidget {

  final List seats;
  final List<String> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function onSeatTap;

  const RoomUI({
    super.key,
    required this.seats,
    required this.messages,
    required this.controller,
    required this.onSend,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F0F1A),
            Color(0xFF1B1B2F),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      child: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const Text(
                    "Voice Party",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "LIVE ${seats.length}/12",
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),

            /// SEATS
            Expanded(
              flex: 3,
              child: SeatGrid(
                seats: seats,
                onSeatTap: onSeatTap,
              ),
            ),

            /// CHAT
            Expanded(
              flex: 2,
              child: ChatPanel(
                messages: messages,
                controller: controller,
                onSend: onSend,
              ),
            ),

            /// NAVBAR
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: BottomControls(),
            ),

          ],
        ),
      ),
    );
  }
}
