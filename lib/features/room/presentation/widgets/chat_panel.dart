import 'package:flutter/material.dart';

class ChatPanel extends StatelessWidget {

  final List<String> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onClose;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      child: Column(
        children: [

          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              const Text(
                "Chat",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                icon: const Icon(Icons.close,color: Colors.white),
                onPressed: onClose,
              )

            ],
          ),

          /// MESSAGES
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder:(context,index){

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical:4),
                  child: Text(
                    messages[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                );

              },
            ),
          ),

          /// INPUT
          Row(
            children: [

              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Type message",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.send,color: Colors.blue),
                onPressed: onSend,
              )

            ],
          )

        ],
      ),

    );

  }

}
