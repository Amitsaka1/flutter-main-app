import 'package:flutter/material.dart';

class ProfileFormSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileFormSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );

    // ================= UI END =================
  }
}
