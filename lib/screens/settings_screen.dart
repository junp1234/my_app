import 'package:flutter/material.dart';

import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.initial});
  final AppSettings initial;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings settings = widget.initial;

  Future<void> _pickTime(bool wake) async {
    final minutes = wake ? settings.wakeMinutes : settings.sleepMinutes;
    final initial = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (wake) {
        settings = settings.copyWith(wakeMinutes: picked.hour * 60 + picked.minute);
      } else {
        settings = settings.copyWith(sleepMinutes: picked.hour * 60 + picked.minute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.settings_outlined),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('dailyGoalMl', '${settings.dailyGoalMl} ml', Slider(
            min: 1000,
            max: 4000,
            divisions: 30,
            value: settings.dailyGoalMl.toDouble(),
            onChanged: (v) => setState(() => settings = settings.copyWith(dailyGoalMl: v.round())),
          )),
          _tile('stepMl', '${settings.stepMl} ml', Slider(
            min: 50,
            max: 500,
            divisions: 45,
            value: settings.stepMl.toDouble(),
            onChanged: (v) => setState(() => settings = settings.copyWith(stepMl: v.round())),
          )),
          SwitchListTile(
            title: const Text('reminderEnabled'),
            value: settings.reminderEnabled,
            onChanged: (v) => setState(() => settings = settings.copyWith(reminderEnabled: v)),
          ),
          ListTile(
            title: const Text('wakeTime'),
            trailing: Text('${(settings.wakeMinutes ~/ 60).toString().padLeft(2, '0')}:${(settings.wakeMinutes % 60).toString().padLeft(2, '0')}'),
            onTap: () => _pickTime(true),
          ),
          ListTile(
            title: const Text('sleepTime'),
            trailing: Text('${(settings.sleepMinutes ~/ 60).toString().padLeft(2, '0')}:${(settings.sleepMinutes % 60).toString().padLeft(2, '0')}'),
            onTap: () => _pickTime(false),
          ),
          ListTile(
            title: const Text('intervalMinutes'),
            trailing: DropdownButton<int>(
              value: settings.intervalMinutes,
              items: const [60, 90, 120].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => settings = settings.copyWith(intervalMinutes: v));
              },
            ),
          ),
          SwitchListTile(
            title: const Text('sound'),
            value: settings.soundEnabled,
            onChanged: (v) => setState(() => settings = settings.copyWith(soundEnabled: v)),
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String value, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            child,
          ],
        ),
      ),
    );
  }
}
