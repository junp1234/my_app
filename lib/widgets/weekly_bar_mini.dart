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
    final average = totals.isEmpty ? 0 : (totals.reduce((a, b) => a + b) / totals.length).round();
    final hasAnyData = normalized.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '今週',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const Spacer(),
              Text(
                '平均 $average mL',
                style: const TextStyle(fontSize: 13, color: AppColors.subtext),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAnyData)
            const Text(
              'まだ記録がありません',
              style: TextStyle(color: AppColors.subtext, fontSize: 13),
            )
          else
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (index) {
                  final total = totals[index];
                  final ratio = goalMl <= 0 ? 0.0 : (total / goalMl).clamp(0.0, 1.0);
                  final barRatio = total == 0 ? 0.1 : ratio.toDouble();
                  final day = days[index];
                  final weekday = _weekdayLabels[day.weekday - 1];

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: barRatio,
                              child: Container(
                                width: 12,
                                decoration: BoxDecoration(
                                  color: total == 0
                                      ? AppColors.primary.withValues(alpha: 0.16)
                                      : AppColors.primary.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(6),
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
        ],
      ),
    );
  }
}
