import 'package:flutter/material.dart';

/// tikboo color system — high-contrast, loud, unapologetically genz.
/// Near-black canvas so the neon accents scream.
class AppColors {
  AppColors._();

  // Canvas
  static const Color ink = Color(0xFF0B0B0F); // base background
  static const Color inkSoft = Color(0xFF15151C); // raised surface
  static const Color inkCard = Color(0xFF1C1C26); // cards
  static const Color stroke = Color(0xFF2A2A38); // hairline borders

  // Neon accents
  static const Color lime = Color(0xFFCBFF4D); // acid lime — primary
  static const Color pink = Color(0xFFFF4D9D); // hot pink
  static const Color violet = Color(0xFF8B5CFF); // electric violet
  static const Color cyan = Color(0xFF45E0FF); // ice cyan
  static const Color tangerine = Color(0xFFFF8A3D); // warm pop

  // Text
  static const Color textHi = Color(0xFFF5F5F7); // near-white
  static const Color textMid = Color(0xFFAFAFC0); // muted
  static const Color textLow = Color(0xFF6C6C7E); // faint

  // Card accent rotation used across the wrapped cards
  static const List<Color> deck = [lime, pink, violet, cyan, tangerine];

  /// Readable text color for content sitting on a neon block.
  static Color onAccent(Color accent) {
    return accent.computeLuminance() > 0.5 ? ink : textHi;
  }
}
