import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class WeeklyBarMini extends StatelessWidget {
  const WeeklyBarMini({
    super.key,
    required this.dailyTotals,
    required this.goalMl,
  });

  final Map<DateTime, int> dailyTotals;
  final int goalMl;

  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List<DateTime>.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - (6 - index)),
    );

    final normalized = <DateTime, int>{
      for (final entry in dailyTotals.entries)
        DateTime(entry.key.year, entry.key.month, entry.key.day): entry.value,
    };

    final totals = days.map((day) => normalized[day] ?? 0).toList(growable: false);
    final hasAnyData = totals.any((value) => value > 0);

    return Card(
      elevation: 0.2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (index) {
                  final total = totals[index];
                  final ratio = goalMl <= 0 ? 0.0 : (total / goalMl).clamp(0.0, 1.0).toDouble();
                  final heightFactor = total == 0 ? 0.08 : ratio.clamp(0.08, 1.0);
                  final weekday = _weekdayLabels[days[index].weekday - 1];

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: heightFactor,
                              child: Container(
                                width: 12,
                                decoration: BoxDecoration(
                                  color: total == 0
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.primary.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weekday,
                          style: const TextStyle(fontSize: 11, color: AppColors.subtext),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            if (!hasAnyData) ...[
              const SizedBox(height: 8),
              const Text(
                'まだ記録がありません。水を追加するとここに反映されます。',
                style: TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
