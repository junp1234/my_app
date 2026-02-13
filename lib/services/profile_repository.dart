import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final intensityIndex = prefs.getInt('profileActivityIntensity') ?? UserProfile.defaults.activityIntensity.index;

    return UserProfile(
      heightCm: prefs.getDouble('profileHeightCm') ?? UserProfile.defaults.heightCm,
      weightKg: prefs.getDouble('profileWeightKg') ?? UserProfile.defaults.weightKg,
      age: prefs.getInt('profileAge') ?? UserProfile.defaults.age,
      activityIntensity: ActivityIntensity.values[intensityIndex.clamp(0, ActivityIntensity.values.length - 1)],
      pregnant: prefs.getBool('profilePregnant') ?? UserProfile.defaults.pregnant,
      breastfeeding: prefs.getBool('profileBreastfeeding') ?? UserProfile.defaults.breastfeeding,
    );
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('profileHeightCm', profile.heightCm);
    await prefs.setDouble('profileWeightKg', profile.weightKg);
    await prefs.setInt('profileAge', profile.age);
    await prefs.setInt('profileActivityIntensity', profile.activityIntensity.index);
    await prefs.setBool('profilePregnant', profile.pregnant);
    await prefs.setBool('profileBreastfeeding', profile.breastfeeding);
  }
}
