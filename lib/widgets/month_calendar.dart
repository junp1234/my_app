import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.dailyTotals,
    required this.goalMl,
    required this.focusedMonth,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final Map<DateTime, int> dailyTotals;
  final int goalMl;
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final firstWeekdayOffset = monthStart.weekday % 7;
    final gridStart = DateTime(monthStart.year, monthStart.month, 1 - firstWeekdayOffset);
    final cells = List<DateTime>.generate(
      42,
      (index) => DateTime(gridStart.year, gridStart.month, gridStart.day + index),
    );

    final normalizedSelected = _normalize(selectedDay);
    final today = _normalize(DateTime.now());
    final selectedTotal = dailyTotals[normalizedSelected] ?? 0;
    final selectedRatio = goalMl <= 0 ? 0 : ((selectedTotal / goalMl) * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                  onPressed: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month - 1, 1),
                  ),
                ),
                Expanded(
                  child: Text(
                    DateFormat.yMMMM('ja').format(monthStart),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                  onPressed: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month + 1, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const ['日', '月', '火', '水', '木', '金', '土']
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.subtext,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 44,
              ),
              itemBuilder: (context, index) {
                final day = _normalize(cells[index]);
                final inMonth = day.month == focusedMonth.month;
                final isSelected = day == normalizedSelected;
                final isToday = day == today;
                final total = dailyTotals[day] ?? 0;
                final hasWater = total > 0;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onDaySelected(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primarySoft : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday ? AppColors.primary : Colors.transparent,
                        width: isToday ? 1.2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: inMonth
                                ? AppColors.text
                                : AppColors.subtext.withOpacity(0.55),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasWater
                                ? AppColors.primary.withOpacity(inMonth ? 0.7 : 0.35)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${DateFormat.yMd('ja').format(normalizedSelected)}: $selectedTotal mL  /  $selectedRatio%',
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _normalize(DateTime day) => DateTime(day.year, day.month, day.day);
}
