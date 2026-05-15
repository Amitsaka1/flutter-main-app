import 'package:flutter/material.dart';

class ProfileFormDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const ProfileFormDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
      ),
      items: items,
      onChanged: onChanged,
    );

    // ================= UI END =================
  }
}
