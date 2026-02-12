import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/intake_event.dart';
import 'package:my_app/services/progress_calculator.dart';

void main() {
  test('totals only events in local day range', () {
    final events = [
      IntakeEvent(id: 1, timestamp: DateTime(2026, 1, 10, 23, 50), amountMl: 100),
      IntakeEvent(id: 2, timestamp: DateTime(2026, 1, 11, 0, 10), amountMl: 120),
      IntakeEvent(id: 3, timestamp: DateTime(2026, 1, 11, 9, 00), amountMl: 200),
      IntakeEvent(id: 4, timestamp: DateTime(2026, 1, 12, 0, 0), amountMl: 300),
    ];

    expect(totalForLocalDay(events, DateTime(2026, 1, 11)), 320);
  });
}
