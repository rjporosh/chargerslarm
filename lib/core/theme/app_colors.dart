import 'package:flutter/material.dart';

/// ChargeAlarm brand palette. Centralized so light/dark themes and all
/// widgets stay visually consistent without repeating hex values.
class AppColors {
  const AppColors._();

  // Brand
  static const seed = Color(0xFF2DD4BF); // teal — "charge" energy
  static const accentAmber = Color(0xFFF59E0B); // target/warning accent
  static const dangerRed = Color(0xFFEF4444);

  // Light surfaces
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);

  // Dark surfaces
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF141B2D);
}
