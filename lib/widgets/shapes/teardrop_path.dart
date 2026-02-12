import 'package:flutter/material.dart';

Path buildTeardropPath(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w / 2, 0)
    ..quadraticBezierTo(w * 0.98, h * 0.28, w * 0.78, h * 0.76)
    ..quadraticBezierTo(w * 0.64, h, w / 2, h)
    ..quadraticBezierTo(w * 0.36, h, w * 0.22, h * 0.76)
    ..quadraticBezierTo(w * 0.02, h * 0.28, w / 2, 0)
    ..close();
}
