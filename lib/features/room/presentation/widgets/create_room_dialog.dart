import 'package:flutter/material.dart';

class CreateRoomDialog extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final Future<void> Function() onStart;

  const CreateRoomDialog({
    super.key,
    required this.nameController,
    required this.descController,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return AlertDialog(
      title: const Text(
        "Start Room",
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,

        children: [

          TextField(
            controller: nameController,

            decoration:
                const InputDecoration(
              hintText: "Room name",
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: descController,

            decoration:
                const InputDecoration(
              hintText:
                  "Description (optional)",
            ),
          ),
        ],
      ),

      actions: [

        TextButton(
          onPressed: () =>
              Navigator.pop(context),

          child: const Text(
            "Cancel",
          ),
        ),

        ElevatedButton(
          onPressed: onStart,

          child: const Text(
            "Start",
          ),
        ),
      ],
    );

    // ================= UI END =================
  }
}
