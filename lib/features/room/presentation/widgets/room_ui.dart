import 'package:flutter/material.dart';
import 'chat_panel.dart';
import 'seat_grid.dart';
import 'bottom_controls.dart';

class RoomUI extends StatelessWidget {

  final List seats;
  final List messages;
  final TextEditingController controller;
  final Function onSend;
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

    return Stack(
      children: [

        /// BACKGROUND
        Container(
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
        ),

        /// HEADER
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Text(
                  "Voice Party",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 12),

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
        ),

        /// MAIN CONTENT
        Positioned.fill(
          top: 100,
          bottom: 100,
          child: Row(
            children: [

              /// CHAT PANEL
              SizedBox(
                width: 250,
                child: ChatPanel(
                  messages: messages,
                  controller: controller,
                  onSend: onSend,
                ),
              ),

              /// SEAT GRID
              Expanded(
                child: SeatGrid(
                  seats: seats,
                  onSeatTap: onSeatTap,
                ),
              ),
            ],
          ),
        ),

        /// BOTTOM CONTROLS
        const Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: BottomControls(),
        ),

      ],
    );
  }
}
