import 'package:flutter/material.dart';

InputDecoration createProfileInputDecoration(
  String label,
) {

  // ================= UI START =================

  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: Colors.white70,
    ),
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );

  // ================= UI END =================
}
