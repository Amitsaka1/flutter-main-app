import 'package:flutter/material.dart';
import 'create_profile_input_decoration.dart';

class CreateProfileDropdown<T>
    extends StatelessWidget {

  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const CreateProfileDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return DropdownButtonFormField<T>(
      value: value,
      decoration: createProfileInputDecoration(label),
      dropdownColor: const Color(0xFF243B55),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );

    // ================= UI END =================
  }
}
