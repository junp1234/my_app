import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../models/intake_event.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repository, required this.settings});

  final IntakeRepository repository;
  final AppSettings settings;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DateTime _month = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, int> _totals = {};
  List<IntakeEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final totals = await widget.repository.getDailyTotalsForMonth(_month);
    final events = await widget.repository.getEventsForDay(_selectedDay);
    if (!mounted) return;
    setState(() {
      _totals = totals;
      _events = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(title: const Icon(Icons.access_time)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(DateFormat.yMMMM().format(_month), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.1),
                itemCount: daysInMonth + start.weekday - 1,
                itemBuilder: (context, index) {
                  if (index < start.weekday - 1) return const SizedBox.shrink();
                  final day = index - start.weekday + 2;
                  final date = DateTime(_month.year, _month.month, day);
                  final total = _totals[date] ?? 0;
                  final achieved = total >= widget.settings.dailyGoalMl;
                  return InkWell(
                    onTap: () async {
                      _selectedDay = date;
                      _events = await widget.repository.getEventsForDay(date);
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: DateUtils.isSameDay(date, _selectedDay) ? const Color(0x1A70BDF4) : Colors.transparent,
                      ),
                      child: Center(
                        child: achieved
                            ? const Icon(Icons.water_drop_rounded, size: 15, color: Color(0xFF68B8F2))
                            : Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0x55333F4F), shape: BoxShape.circle)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _events.length,
                itemBuilder: (context, i) {
                  final e = _events[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.water_drop_rounded, color: Color(0xFF70BDF4)),
                        const SizedBox(height: 6),
                        Container(width: 3, height: 22, color: const Color(0x3370BDF4)),
                        const SizedBox(height: 6),
                        Text(DateFormat.Hm().format(e.timestamp), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
