import 'package:flutter/material.dart';

class ProfileFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const ProfileFormTextField({
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
      decoration: InputDecoration(
        labelText: label,
      ),
      validator: validator,
    );

    // ================= UI END =================
  }
}
