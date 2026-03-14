import 'package:flutter/material.dart';
import 'chat_panel.dart';
import 'seat_grid.dart';
import 'bottom_controls.dart';

class RoomUI extends StatelessWidget {

  final bool loading;
  final List<Map<String, dynamic>> seats;
  final List<String> messages;
  final TextEditingController chatController;
  final VoidCallback onSend;
  final VoidCallback onLeave;
  final Function(Map<String,dynamic>) onSeatTap;

  const RoomUI({
    super.key,
    required this.loading,
    required this.seats,
    required this.messages,
    required this.chatController,
    required this.onSend,
    required this.onLeave,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      body: Stack(
        children: [

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0F1A),
                  Color(0xFF1B1B2F),
                ],
              ),
            ),
          ),

          Row(
            children: [

              ChatPanel(
                messages: messages,
                controller: chatController,
                onSend: onSend,
              ),

              Expanded(
                child: SeatGrid(
                  seats: seats,
                  onSeatTap: onSeatTap,
                ),
              ),

            ],
          ),

          BottomControls(),

          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close,color: Colors.white),
              onPressed: onLeave,
            ),
          )

        ],
      ),

    );

  }

}
