import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../services/settings_repository.dart';
import '../theme/app_colors.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.initial});
  final AppSettings initial;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _intervalOptions = [15, 30, 45, 60, 75, 90, 105, 120];

  final _settingsRepo = SettingsRepository.instance;
  late AppSettings settings = widget.initial;

  @override
  void initState() {
    super.initState();
    _reloadFromPrefs();
  }

  Future<void> _reloadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final reloaded = settings.copyWith(
      dailyGoalMl: prefs.getInt('dailyGoalMl') ?? settings.dailyGoalMl,
      stepMl: prefs.getInt('stepMl') ?? settings.stepMl,
      reminderEnabled: prefs.getBool('reminderEnabled') ?? settings.reminderEnabled,
    );
    if (!mounted) {
      return;
    }
    setState(() => settings = reloaded);
  }

  Future<void> _updateSettings(AppSettings next) async {
    setState(() => settings = next);
    await _settingsRepo.save(next);
  }

  Future<void> _pickTime(bool wake) async {
    final minutes = wake ? settings.wakeMinutes : settings.sleepMinutes;
    final initial = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    if (wake) {
      await _updateSettings(settings.copyWith(wakeMinutes: picked.hour * 60 + picked.minute));
    } else {
      await _updateSettings(settings.copyWith(sleepMinutes: picked.hour * 60 + picked.minute));
    }
  }

  Future<void> _openProfile() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProfileScreen(isFirstRun: false)),
    );
    if (changed == true) {
      await _reloadFromPrefs();
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, settings);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final nearestInterval = _intervalOptions.reduce((a, b) =>
        (settings.intervalMinutes - a).abs() <= (settings.intervalMinutes - b).abs() ? a : b);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Icon(Icons.settings_outlined),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, settings),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tile(
              'dailyGoalMl',
              '${settings.dailyGoalMl} ml',
              _blueSlider(
                Slider(
                  min: 1000,
                  max: 4000,
                  divisions: 30,
                  value: settings.dailyGoalMl.toDouble(),
                  onChanged: (v) => _updateSettings(settings.copyWith(dailyGoalMl: v.round())),
                ),
              ),
            ),

            ListTile(
              title: const Text('profile'),
              subtitle: const Text('プロフィールから必要水分量を計算'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openProfile,
            ),

            _tile(
              'stepMl',
              '${settings.stepMl} ml',
              _blueSlider(
                Slider(
                  min: 50,
                  max: 500,
                  divisions: 45,
                  value: settings.stepMl.toDouble(),
                  onChanged: (v) => _updateSettings(settings.copyWith(stepMl: v.round())),
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('reminderEnabled'),
              value: settings.reminderEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => _updateSettings(settings.copyWith(reminderEnabled: v)),
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
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primary.withOpacity(0.45)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'intervalMinutes',
                      style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '間隔: $nearestInterval分',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _intervalOptions
                          .map(
                            (minutes) => ChoiceChip(
                              label: Text('$minutes分'),
                              selected: nearestInterval == minutes,
                              onSelected: (_) => _updateSettings(settings.copyWith(intervalMinutes: minutes)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('sound'),
              value: settings.soundEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => _updateSettings(settings.copyWith(soundEnabled: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, String value, Widget child) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.blueGrey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _blueSlider(Widget child) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.15),
        inactiveTrackColor: AppColors.primary.withOpacity(0.25),
      ),
      child: child,
    );
  }
}
