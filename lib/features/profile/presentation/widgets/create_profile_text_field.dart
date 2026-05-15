import 'package:flutter/material.dart';
import 'create_profile_input_decoration.dart';

class CreateProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const CreateProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: createProfileInputDecoration(label),
      validator: validator,
    );

    // ================= UI END =================
  }
}
