import 'package:flutter/material.dart';

class BottomControls extends StatelessWidget {

  final VoidCallback onChat;
  final VoidCallback onGift;

  const BottomControls({
    super.key,
    required this.onChat,
    required this.onGift,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          /// GIFT
          GestureDetector(
            onTap: onGift,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
                SizedBox(height: 4),
                Text(
                  "Gift",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),

          /// CHAT BUTTON
          GestureDetector(
            onTap: onChat,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  "Chat",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),

          /// MIC
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, color: Colors.white, size: 24),
              SizedBox(height: 4),
              Text(
                "Mic",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              )
            ],
          ),

          /// FRAME
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, color: Colors.white, size: 24),
              SizedBox(height: 4),
              Text(
                "Frame",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              )
            ],
          ),

        ],
      ),
    );
  }
}
