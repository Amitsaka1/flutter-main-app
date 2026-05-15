import 'package:flutter/material.dart';

class CreateProfileCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const CreateProfileCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        const Text(
          "Have Place",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );

    // ================= UI END =================
  }
}
