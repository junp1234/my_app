import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class WeeklyProgressRow extends StatelessWidget {
  const WeeklyProgressRow({
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
    final achievedCount = totals.where((value) => goalMl > 0 && value >= goalMl).length;
    final totalWeekMl = totals.fold<int>(0, (sum, value) => sum + value);
    final avgLiters = (totalWeekMl / 7) / 1000;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Weekly',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const Spacer(),
                Text(
                  '平均 ${avgLiters.toStringAsFixed(1)}L',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.subtext),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (index) {
                  final day = days[index];
                  final total = totals[index];
                  final progress = goalMl <= 0 ? 0.0 : (total / goalMl).clamp(0.0, 1.2).toDouble();
                  final isToday = day == today;
                  final achieved = progress >= 1.0;
                  final midProgress = progress >= 0.5 && progress < 1.0;
                  final barOpacity = achieved ? 1.0 : (midProgress ? 0.8 : 0.35);
                  final minHeight = progress < 0.5 ? 0.2 : 0.35;
                  final heightFactor = progress == 0 ? minHeight : progress.clamp(minHeight, 1.0);

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 16,
                          child: achieved
                              ? const Icon(Icons.check_circle, size: 15, color: AppColors.primary)
                              : midProgress
                                  ? Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 18,
                          height: 56,
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            border: isToday ? Border.all(color: AppColors.primary, width: 1.1) : null,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: FractionallySizedBox(
                            heightFactor: heightFactor,
                            child: Container(
                              width: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: barOpacity),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _weekdayLabels[day.weekday - 1],
                          style: const TextStyle(fontSize: 11, color: AppColors.subtext),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '達成 $achievedCount/7',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.subtext),
            ),
          ],
        ),
      ),
    );
  }
}
