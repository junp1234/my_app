import 'package:flutter/material.dart';

class GlassWaterPalette {
  const GlassWaterPalette._();

  static const Color top = Color(0xCCEAF9FF);
  static const Color mid = Color(0xC28FD8FF);
  static const Color midDeep = Color(0xCC5CB8EE);
  static const Color bottom = Color(0xD94593CC);
  static const Color base = Color(0xFF8BD4FF);

  static Color fullBackgroundTint({double amount = 0.32}) {
    return Color.lerp(mid, Colors.white, amount) ?? mid;
  }
}
