import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../services/daily_totals_service.dart';
import '../widgets/weekly_bar_mini.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repository, required this.settings});

  final IntakeRepository repository;
  final AppSettings settings;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _goalMl = 1500;
  Map<DateTime, int> _totals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final goalMl = prefs.getInt('dailyGoalMl') ?? 1500;
    final totals = await DailyTotalsService.getLastNDays(7);
    if (!mounted) {
      return;
    }
    setState(() {
      _goalMl = goalMl;
      _totals = totals;
      _loading = false;
    });
  }

  List<DateTime> _buildLastSevenDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<DateTime>.generate(7, (index) {
      return DateTime(today.year, today.month, today.day - index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildLastSevenDays();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            WeeklyBarMini(dailyTotals: _totals, goalMl: _goalMl),
            const SizedBox(height: 16),
            Text('直近7日', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...days.map((day) {
                final total = _totals[day] ?? 0;
                final ratio = _goalMl <= 0 ? 0.0 : (total / _goalMl);
                final percent = (ratio * 100).round();
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.12)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    title: Text(DateFormat.Md().format(day)),
                    subtitle: Text('$total mL'),
                    trailing: Text('$percent%'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
