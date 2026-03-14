import 'package:flutter/material.dart';

class BottomControls extends StatelessWidget {

  const BottomControls({super.key});

  @override
  Widget build(BuildContext context) {

    return Positioned(

      bottom:30,
      left:0,
      right:0,

      child: Center(
        child: Container(

          padding: const EdgeInsets.symmetric(
            horizontal:30,
            vertical:12,
          ),

          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),

          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(Icons.card_giftcard,color: Colors.amber),

              SizedBox(width:40),

              Icon(Icons.mic,color: Colors.white),

              SizedBox(width:40),

              Icon(Icons.image,color: Colors.white),

            ],
          ),

        ),
      ),

    );

  }

}
