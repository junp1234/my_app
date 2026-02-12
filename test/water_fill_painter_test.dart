import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/app_settings.dart';
import 'package:my_app/widgets/painters/water_fill_painter.dart';

void main() {
  test('default stepMl is reduced to 150ml', () {
    expect(AppSettings.defaults.stepMl, 150);
  });

  test('visual fill keeps headroom even at 100 percent progress', () {
    const innerRect = Rect.fromLTWH(0, 0, 200, 200);

    final fullY = WaterFillPainter.waterTopYForProgress(innerRect, 1.0);
    final nearTopLimit = innerRect.top + 24;

    expect(fullY, greaterThan(nearTopLimit));
    expect(WaterFillPainter.visualFillForProgress(1.0), closeTo(0.82, 0.0001));
  });
}
