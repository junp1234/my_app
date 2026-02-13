import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/hydration_calculator.dart';
import '../services/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

    _heightController.text = profile.heightCm.toStringAsFixed(1);
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
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final age = int.tryParse(_ageController.text);

    if (height == null || weight == null || age == null || height <= 0 || weight <= 0 || age <= 0) {
      return null;
    }

    return UserProfile(
      heightCm: height,
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

    final recommended = HydrationCalculator.calculateDailyMl(profile);
    await _repo.save(profile);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, recommended);
  }

  String _activityLabel(ActivityIntensity intensity) {
    return switch (intensity) {
      ActivityIntensity.none => 'なし',
      ActivityIntensity.light => '軽い',
      ActivityIntensity.normal => '普通',
      ActivityIntensity.strong => '強い',
    };
  }

  @override
  Widget build(BuildContext context) {
    final liters = (_recommendedMl / 1000).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '身長 (cm)'),
              validator: _positiveNumberValidator,
            ),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '体重 (kg)'),
              validator: _positiveNumberValidator,
            ),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '年齢'),
              validator: _positiveIntegerValidator,
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
                });
                _recalculate();
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '推奨：$_recommendedMl mL/日（$liters L）',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  String? _positiveNumberValidator(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return '正の数を入力してください';
    }
    return null;
  }

  String? _positiveIntegerValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return '1以上の整数を入力してください';
    }
    return null;
  }
}
