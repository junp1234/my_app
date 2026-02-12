import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/app_settings.dart';
import 'package:my_app/widgets/painters/water_fill_painter.dart';

void main() {
  test('default stepMl remains 50ml', () {
    expect(AppSettings.defaults.stepMl, 50);
  });

  test('100 percent progress fills to the very top', () {
    const innerRect = Rect.fromLTWH(0, 0, 200, 200);

    final fullY = WaterFillPainter.waterTopYForProgress(innerRect, 1.0);

    expect(fullY, innerRect.top);
    expect(WaterFillPainter.visualFillForProgress(1.0), 1.0);
  });

  test('visual fill is progress-linear before full state', () {
    expect(WaterFillPainter.visualFillForProgress(0.5), closeTo(0.5, 0.0001));
  });
}
