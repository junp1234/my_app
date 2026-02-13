import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'hydration_calculator.dart';
import 'settings_repository.dart';

class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  static const String keyHeightCm = 'profile_height_cm';
  static const String keyWeightKg = 'profile_weight_kg';
  static const String keyAge = 'profile_age';
  static const String keyActivity = 'profile_activity';
  static const String keyPregnant = 'profile_pregnant';
  static const String keyLactating = 'profile_lactating';
  static const String keyWaterMl = 'profile_water_ml';
  static const String keyLastCalculatedMl = 'profile_last_calculated_ml';
  static const String keySetupDone = 'profile_setup_done';
  static const String keySetupSkipped = 'profile_setup_skipped';

  final SettingsRepository _settingsRepository = SettingsRepository.instance;

  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final activity = _activityFromString(prefs.getString(keyActivity));

    return UserProfile(
      heightCm: (prefs.getInt(keyHeightCm) ?? UserProfile.defaults.heightCm.toInt()).toDouble(),
      weightKg: prefs.getDouble(keyWeightKg) ?? UserProfile.defaults.weightKg,
      age: prefs.getInt(keyAge) ?? UserProfile.defaults.age,
      activityIntensity: activity,
      pregnant: prefs.getBool(keyPregnant) ?? UserProfile.defaults.pregnant,
      breastfeeding: prefs.getBool(keyLactating) ?? UserProfile.defaults.breastfeeding,
    );
  }

  Future<int> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final recommendedMl = HydrationCalculator.calculateDailyMl(profile);

    await prefs.setInt(keyHeightCm, profile.heightCm.round());
    await prefs.setDouble(keyWeightKg, profile.weightKg);
    await prefs.setInt(keyAge, profile.age);
    await prefs.setString(keyActivity, _activityToString(profile.activityIntensity));
    await prefs.setBool(keyPregnant, profile.pregnant);
    await prefs.setBool(keyLactating, profile.breastfeeding);
    await prefs.setInt(keyWaterMl, recommendedMl);
    await prefs.setInt(keyLastCalculatedMl, recommendedMl);
    await prefs.setInt('dailyGoalMl', recommendedMl);
    await prefs.setBool(keySetupDone, true);
    await prefs.setBool(keySetupSkipped, false);

    final currentSettings = await _settingsRepository.load();
    await _settingsRepository.save(currentSettings.copyWith(dailyGoalMl: recommendedMl));

    return recommendedMl;
  }

  Future<void> skipInitialSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySetupSkipped, true);
  }

  Future<bool> shouldShowInitialSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final isDone = prefs.getBool(keySetupDone) ?? false;
    final isSkipped = prefs.getBool(keySetupSkipped) ?? false;
    return !isDone && !isSkipped;
  }

  ActivityIntensity _activityFromString(String? value) {
    return switch (value) {
      'light' => ActivityIntensity.light,
      'normal' => ActivityIntensity.normal,
      'hard' => ActivityIntensity.strong,
      _ => ActivityIntensity.none,
    };
  }

  String _activityToString(ActivityIntensity value) {
    return switch (value) {
      ActivityIntensity.none => 'none',
      ActivityIntensity.light => 'light',
      ActivityIntensity.normal => 'normal',
      ActivityIntensity.strong => 'hard',
    };
  }
}
