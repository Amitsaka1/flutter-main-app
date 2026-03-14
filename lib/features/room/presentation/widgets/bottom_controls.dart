import 'package:flutter/material.dart';

class BottomControls extends StatelessWidget {

  const BottomControls({super.key});

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
        children: const [

          Column(
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

          Column(
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

          Column(
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
