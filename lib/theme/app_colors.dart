import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFF6F9FF);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF5AB8FF);
  static const Color border = Color(0xFFE1ECFF);

  static final Color primarySoft = primary.withValues(alpha: 0.12);

  static const Color text = Color(0xFF1E2430);
  static const Color subtext = Color(0xFF6B778C);

  static final Color primaryStrong = primary.withValues(alpha: 0.95);
}
