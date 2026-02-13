import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/hydration_calculator.dart';
import '../services/profile_repository.dart';
import '../theme/app_colors.dart';

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

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.subtext),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liters = (_recommendedMl / 1000).toStringAsFixed(1);

    return WillPopScope(
      onWillPop: () async => !widget.isFirstRun,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('プロフィール', style: TextStyle(color: AppColors.text)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          iconTheme: const IconThemeData(color: AppColors.primary),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.water_drop_rounded, color: AppColors.primary),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned(
              top: 12,
              right: 20,
              child: Icon(
                Icons.water_drop_rounded,
                size: 76,
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _sectionCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('身長 (cm)'),
                          validator: _heightValidator,
                          style: const TextStyle(color: AppColors.text),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _fieldDecoration('体重 (kg)'),
                          validator: _weightValidator,
                          style: const TextStyle(color: AppColors.text),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('年齢'),
                          validator: _ageValidator,
                          style: const TextStyle(color: AppColors.text),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ActivityIntensity>(
                          value: _activity,
                          decoration: _fieldDecoration('運動強度'),
                          items: ActivityIntensity.values
                              .map(
                                (value) => DropdownMenuItem<ActivityIntensity>(
                                  value: value,
                                  child: Text(_activityLabel(value), style: const TextStyle(color: AppColors.text)),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('妊娠', style: TextStyle(color: AppColors.text)),
                          value: _pregnant,
                          activeColor: AppColors.primary,
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
                        const Divider(color: AppColors.border, height: 1),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('授乳', style: TextStyle(color: AppColors.text)),
                          value: _breastfeeding,
                          activeColor: AppColors.primary,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('推奨', style: TextStyle(color: AppColors.subtext, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_recommendedMl',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' mL',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '   ($liters L)',
                                  style: const TextStyle(
                                    color: AppColors.subtext,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                  if (widget.isFirstRun) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _skipForNow,
                      child: const Text('今はスキップ', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
