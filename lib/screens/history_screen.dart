import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../models/intake_event.dart';
import '../services/settings_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repository, required this.settings});

  final IntakeRepository repository;
  final AppSettings settings;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _settingsRepository = SettingsRepository.instance;

  late DateTime _focusedMonth;
  late AppSettings _settings;
  Map<String, int> _dailyTotals = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _settings = widget.settings;
    _loadMonth();
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final loadedSettings = await _settingsRepository.load();
    final totals = await widget.repository.getDailyTotalsForMonth(_focusedMonth);
    if (!mounted) return;
    setState(() {
      _settings = loadedSettings;
      _dailyTotals = totals;
      _loading = false;
    });
  }

  Future<void> _changeMonth(int offset) async {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset);
    });
    await _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekdayOffset = start.weekday - 1;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = daysInMonth + firstWeekdayOffset;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _loading ? null : () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat.yMMMM().format(_focusedMonth),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((label) => Expanded(
                        child: Center(
                          child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0x88333F4F))),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: totalCells,
                    itemBuilder: (context, index) {
                      if (index < firstWeekdayOffset) {
                        return const SizedBox.shrink();
                      }

                      final day = index - firstWeekdayOffset + 1;
                      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                      final total = _dailyTotals[_dateKey(date)] ?? 0;
                      final goal = _settings.dailyGoalMl;
                      final rate = goal <= 0 ? 0.0 : (total / goal).clamp(0.0, 1.0).toDouble();
                      final percent = (rate * 100).round();

                      return _DayCell(
                        day: day,
                        percent: percent,
                        rate: rate,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _DayDetailScreen(
                                repository: widget.repository,
                                date: date,
                                totalMl: total,
                                goalMl: goal,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  if (_loading) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.percent,
    required this.rate,
    required this.onTap,
  });

  final int day;
  final int percent;
  final double rate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = Color.lerp(const Color(0x00000000), const Color(0xFF5BAEE7), rate) ?? Colors.transparent;

    Widget? badge;
    if (percent >= 100) {
      badge = const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E86CC));
    } else if (percent > 0) {
      badge = Text(
        '$percent%',
        style: const TextStyle(fontSize: 10, color: Color(0xFF4A98D6), fontWeight: FontWeight.w500),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tint.withOpacity(percent == 0 ? 0.04 : 0.14 + (rate * 0.30)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x143C78AA)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$day', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Align(alignment: Alignment.bottomRight, child: badge ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _DayDetailScreen extends StatefulWidget {
  const _DayDetailScreen({
    required this.repository,
    required this.date,
    required this.totalMl,
    required this.goalMl,
  });

  final IntakeRepository repository;
  final DateTime date;
  final int totalMl;
  final int goalMl;

  @override
  State<_DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<_DayDetailScreen> {
  List<IntakeEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await widget.repository.getEventsForDay(widget.date);
    if (!mounted) return;
    setState(() => _events = events);
  }

  @override
  Widget build(BuildContext context) {
    final rate = widget.goalMl <= 0 ? 0.0 : (widget.totalMl / widget.goalMl).clamp(0.0, 1.0).toDouble();
    final percent = (rate * 100).round();

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat.yMMMd().format(widget.date))),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('合計 ${widget.totalMl} ml', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('達成率 ${percent > 100 ? 100 : percent}%', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: _events.isEmpty
                ? const Center(child: Text('記録なし'))
                : ListView.separated(
                    itemCount: _events.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return ListTile(
                        leading: const Icon(Icons.water_drop_rounded, color: Color(0xFF70BDF4)),
                        title: Text('${event.amountMl} ml'),
                        trailing: Text(DateFormat.Hm().format(event.timestamp)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
