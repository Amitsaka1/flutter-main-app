import 'package:flutter/material.dart';

class BottomControls extends StatelessWidget {

  const BottomControls({super.key});

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [

            Column(
              children: [
                Icon(Icons.card_giftcard, color: Colors.amber),
                SizedBox(height: 4),
                Text("Gift",
                    style: TextStyle(color: Colors.white))
              ],
            ),

            SizedBox(width: 40),

            Column(
              children: [
                Icon(Icons.mic, color: Colors.white),
                SizedBox(height: 4),
                Text("Mic",
                    style: TextStyle(color: Colors.white))
              ],
            ),

            SizedBox(width: 40),

            Column(
              children: [
                Icon(Icons.image, color: Colors.white),
                SizedBox(height: 4),
                Text("Frame",
                    style: TextStyle(color: Colors.white))
              ],
            ),

          ],
        ),
      ),
    );
  }
}
