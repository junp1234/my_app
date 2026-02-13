import '../models/user_profile.dart';

class HydrationCalculator {
  static int calculateDailyMl(UserProfile profile) {
    double result = profile.weightKg * 35;

    if (profile.age >= 65) {
      result *= 0.95;
    }

    result += switch (profile.activityIntensity) {
      ActivityIntensity.none => 0,
      ActivityIntensity.light => 400,
      ActivityIntensity.normal => 600,
      ActivityIntensity.strong => 800,
    };

    if (profile.pregnant) {
      result += 300;
    }

    if (profile.breastfeeding) {
      result += 700;
    }

    final clamped = result.clamp(1200, 5000);
    return clamped.round();
  }
}
