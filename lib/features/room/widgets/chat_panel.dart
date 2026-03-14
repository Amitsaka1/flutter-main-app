import 'package:flutter/material.dart';

class ChatPanel extends StatelessWidget {

  final List<String> messages;
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 250,
      margin: const EdgeInsets.only(top:120,bottom:120),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
      ),
      child: Column(
        children: [

          const Padding(
            padding: EdgeInsets.all(10),
            child: Text("Chat",style: TextStyle(color: Colors.white)),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder:(context,index){

                return Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(messages[index],
                  style: const TextStyle(color: Colors.white)),
                );

              },
            ),
          ),

          Row(
            children: [

              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText:"Type message",
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
