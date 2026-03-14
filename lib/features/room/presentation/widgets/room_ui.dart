import 'package:flutter/material.dart';
import 'seat_grid.dart';
import 'chat_panel.dart';
import 'bottom_controls.dart';

class RoomUI extends StatelessWidget {

  final List<Map<String, dynamic>> seats;
  final List<String> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final void Function(Map<String, dynamic>) onSeatTap;

  final bool showChat;
  final VoidCallback onChatToggle;

  final bool showGift;
  final VoidCallback onGiftToggle;

  const RoomUI({
    super.key,
    required this.seats,
    required this.messages,
    required this.controller,
    required this.onSend,
    required this.onSeatTap,
    required this.showChat,
    required this.onChatToggle,
    required this.showGift,
    required this.onGiftToggle,
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
        child: Stack(
          children: [

            /// MAIN CONTENT
            Column(
              children: [

                /// HEADER
                Padding(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "LIVE ${seats.length}/12",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )

                    ],
                  ),
                ),

                /// SEATS GRID
                Expanded(
                  child: SeatGrid(
                    seats: seats,
                    onSeatTap: onSeatTap,
                  ),
                ),

                const SizedBox(height: 80),

              ],
            ),

            /// CHAT PANEL
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),

              bottom: showChat ? 70 : -400,

              left: 0,
              right: 0,

              height: MediaQuery.of(context).size.height / 3,

              child: ChatPanel(
                messages: messages,
                controller: controller,
                onSend: onSend,
                onClose: onChatToggle,
              ),
            ),

            /// GIFT PANEL
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),

              bottom: showGift ? 70 : -400,

              left: 0,
              right: 0,

              height: MediaQuery.of(context).size.height / 3,

              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),

                child: GridView.builder(

                  itemCount: 20,

                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),

                  itemBuilder: (context,index){

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: Colors.amber,
                          ),
                        ),

                        const SizedBox(height:4),

                        const Text(
                          "Gift",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        )

                      ],
                    );

                  },

                ),
              ),
            ),

            /// BOTTOM BAR
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: BottomControls(
                onChat: onChatToggle,
                onGift: onGiftToggle,
              ),
            ),

          ],
        ),
      ),
    );
  }
}
