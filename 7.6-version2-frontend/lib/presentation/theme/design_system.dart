import 'package:flutter/material.dart';

// --- Color System ---
class DSColors {
  DSColors._();

  static const primary = Color(0xFF44C662);
  static const background = Color(0xFFF4F7FA);
  static const textDark = Colors.black87;
  static const textLight = Colors.black54;
  static const white = Colors.white;

  // Semantic Colors
  static const success = Color(0xFF52C41A);
  static const warning = Color(0xFFFFAA00);
  static const error = Color(0xFFFF4D4F);
  static const info = Color(0xFF1890FF);
}

// --- Typography System ---
class DSTextStyles {
  DSTextStyles._();

  static const h1 = TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Poppins', color: DSColors.textDark);
  static const h2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: DSColors.textDark);
  static const h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: DSColors.textDark);
  static const bodyBold = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: DSColors.textDark);
  static const body = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, fontFamily: 'Poppins', color: DSColors.textLight);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'Poppins', color: DSColors.textLight);
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: DSColors.white);
}

// --- Spacing System (8dp grid) ---
class DSSpacings {
  DSSpacings._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 16.0;
  static const double m = 24.0;
  static const double l = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}
