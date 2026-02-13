import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/hydration_calculator.dart';
import '../services/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isFirstRun = false});

  final bool isFirstRun;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProfileRepository.instance;

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  ActivityIntensity _activity = ActivityIntensity.none;
  bool _pregnant = false;
  bool _breastfeeding = false;
  int _recommendedMl = 1200;

  @override
  void initState() {
    super.initState();
    _load();
    _heightController.addListener(_recalculate);
    _weightController.addListener(_recalculate);
    _ageController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await _repo.load();
    if (!mounted) {
      return;
    }

    _heightController.text = profile.heightCm.round().toString();
    _weightController.text = profile.weightKg.toStringAsFixed(1);
    _ageController.text = profile.age.toString();

    setState(() {
      _activity = profile.activityIntensity;
      _pregnant = profile.pregnant;
      _breastfeeding = profile.breastfeeding;
      _recommendedMl = HydrationCalculator.calculateDailyMl(profile);
    });
  }

  void _recalculate() {
    final profile = _currentProfileOrNull();
    if (profile == null) {
      return;
    }
    setState(() {
      _recommendedMl = HydrationCalculator.calculateDailyMl(profile);
    });
  }

  UserProfile? _currentProfileOrNull() {
    final height = int.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final age = int.tryParse(_ageController.text);

    if (height == null || weight == null || age == null) {
      return null;
    }

    return UserProfile(
      heightCm: height.toDouble(),
      weightKg: weight,
      age: age,
      activityIntensity: _activity,
      pregnant: _pregnant,
      breastfeeding: _breastfeeding,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profile = _currentProfileOrNull();
    if (profile == null) {
      return;
    }

    final recommendedMl = HydrationCalculator.calculateDailyMl(profile);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(ProfileRepository.keyHeightCm, profile.heightCm.round());
    await prefs.setDouble(ProfileRepository.keyWeightKg, profile.weightKg);
    await prefs.setInt(ProfileRepository.keyAge, profile.age);
    await prefs.setString(ProfileRepository.keyActivity, _activityLabel(profile.activityIntensity));
    await prefs.setBool(ProfileRepository.keyPregnant, profile.pregnant);
    await prefs.setBool(ProfileRepository.keyLactating, profile.breastfeeding);
    await prefs.setInt('profile_water_ml', recommendedMl);
    await prefs.setInt('dailyGoalMl', recommendedMl);
    await prefs.setBool('profile_setup_done', true);
    await prefs.setBool('profile_setup_skipped', false);
    debugPrint('profile save recommendedMl=$recommendedMl');

    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  Future<void> _skipForNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_setup_skipped', true);
    debugPrint('profile skipped');
    if (!mounted) {
      return;
    }
    Navigator.pop(context, false);
  }

  String _activityLabel(ActivityIntensity intensity) {
    return switch (intensity) {
      ActivityIntensity.none => 'none',
      ActivityIntensity.light => 'light',
      ActivityIntensity.normal => 'normal',
      ActivityIntensity.strong => 'hard',
    };
  }

  @override
  Widget build(BuildContext context) {
    final liters = (_recommendedMl / 1000).toStringAsFixed(1);

    return WillPopScope(
      onWillPop: () async => !widget.isFirstRun,
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '身長 (cm)'),
                validator: _heightValidator,
              ),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '体重 (kg)'),
                validator: _weightValidator,
              ),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '年齢'),
                validator: _ageValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ActivityIntensity>(
                value: _activity,
                decoration: const InputDecoration(labelText: '運動強度'),
                items: ActivityIntensity.values
                    .map(
                      (value) => DropdownMenuItem<ActivityIntensity>(
                        value: value,
                        child: Text(_activityLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _activity = value;
                  });
                  _recalculate();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('妊娠'),
                value: _pregnant,
                onChanged: (value) {
                  setState(() {
                    _pregnant = value;
                    if (value) {
                      _breastfeeding = false;
                    }
                  });
                  _recalculate();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('授乳'),
                value: _breastfeeding,
                onChanged: (value) {
                  setState(() {
                    _breastfeeding = value;
                    if (value) {
                      _pregnant = false;
                    }
                  });
                  _recalculate();
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '推奨: $_recommendedMl mL/日 ($liters L)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('保存')),
              if (widget.isFirstRun) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: _skipForNow, child: const Text('今はスキップ')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _heightValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 80 || parsed > 250) {
      return '80〜250の整数で入力してください';
    }
    return null;
  }

  String? _weightValidator(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed < 20 || parsed > 300) {
      return '20〜300の範囲で入力してください';
    }
    return null;
  }

  String? _ageValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 0 || parsed > 120) {
      return '0〜120の整数で入力してください';
    }
    return null;
  }
}
