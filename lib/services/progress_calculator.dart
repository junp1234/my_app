import '../models/intake_event.dart';

int totalForLocalDay(List<IntakeEvent> events, DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  return events
      .where((e) => !e.timestamp.isBefore(start) && e.timestamp.isBefore(end))
      .fold(0, (sum, e) => sum + e.amountMl);
}
