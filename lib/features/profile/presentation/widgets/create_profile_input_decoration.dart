import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CREATE PROFILE INPUT DECORATION  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

// ── Palette ──────────────────────────────────
const _goldA     = Color(0xFFD4A843);
const _border    = Color(0xFF2A2A3A);
const _surface   = Color(0xFF0E0E18);
const _textMuted = Color(0xFF55556A);
const _textPrime = Color(0xFFF0EDE8);
const _error     = Color(0xFFE05C5C);

// ─────────────────────────────────────────────
//  Main decoration function
// ─────────────────────────────────────────────

InputDecoration createProfileInputDecoration(
  String label, {
  bool   isFocused = false,
  bool   hasValue  = false,
  String? errorText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {

  // ================= UI START =================

  final bool isActive = isFocused || hasValue;
  final bool hasError = errorText != null && errorText.isNotEmpty;

  return InputDecoration(

    // ── Label ──────────────────────────────────
    labelText: label,
    labelStyle: TextStyle(
      color:       isActive ? _goldA : _textMuted,
      fontSize:    13,
      fontWeight:  isActive ? FontWeight.w600 : FontWeight.w400,
      letterSpacing: 0.3,
    ),
    floatingLabelStyle: const TextStyle(
      color:       _goldA,
      fontSize:    12,
      fontWeight:  FontWeight.w600,
      letterSpacing: 0.4,
    ),

    // ── Fill ───────────────────────────────────
    filled:    true,
    fillColor: _surface,

    // ── Prefix / Suffix ────────────────────────
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,

    // ── Content padding ────────────────────────
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical:   15,
    ),
    isDense: true,

    // ── Borders ────────────────────────────────
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _goldA.withOpacity(0.7),
        width: 1.2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _error.withOpacity(0.6),
        width: 1,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _error.withOpacity(0.8),
        width: 1.2,
      ),
    ),

    // ── Error style ────────────────────────────
    errorText:  errorText,
    errorStyle: TextStyle(
      color:       _error.withOpacity(0.85),
      fontSize:    11.5,
      letterSpacing: 0.2,
    ),

    // ── Hint ───────────────────────────────────
    hintStyle: TextStyle(
      color:    _textMuted.withOpacity(0.6),
      fontSize: 13.5,
    ),

  );

  // ================= UI END =================
}
