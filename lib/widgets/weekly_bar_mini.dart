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
  static const _barAreaHeight = 84.0;
  static const _maxBarHeight = 56.0;

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Weekly',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Text(
                  '平均 ${avgLiters.toStringAsFixed(1)}L',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtext,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: _barAreaHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(days.length, (index) {
                    final day = days[index];
                    final total = totals[index];
                    final progress = goalMl <= 0 ? 0.0 : (total / goalMl).toDouble();
                    final isToday = day == today;
                    final achieved = progress >= 1.0;
                    final midProgress = progress >= 0.5 && progress < 1.0;
                    final barOpacity = achieved ? 1.0 : (midProgress ? 0.8 : 0.35);
                    final minHeight = progress < 0.5
                        ? (_maxBarHeight * 0.2)
                        : (_maxBarHeight * 0.35);
                    final h = (progress == 0 ? minHeight : (_maxBarHeight * progress))
                        .clamp(0.0, _maxBarHeight);

                    return Expanded(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 18,
                            height: _maxBarHeight,
                            alignment: Alignment.bottomCenter,
                            decoration: BoxDecoration(
                              border: isToday
                                  ? Border.all(color: AppColors.primary, width: 1.1)
                                  : null,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 12,
                                height: h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: barOpacity),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: _maxBarHeight + 4,
                            child: SizedBox(
                              height: 16,
                              child: achieved
                                  ? const Icon(
                                      Icons.check_circle,
                                      size: 15,
                                      color: AppColors.primary,
                                    )
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
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(days.length, (index) {
                final day = days[index];

                return Expanded(
                  child: Center(
                    child: Text(
                      _weekdayLabels[day.weekday - 1],
                      style: const TextStyle(fontSize: 11, color: AppColors.subtext),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '達成 $achievedCount/7',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.subtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
