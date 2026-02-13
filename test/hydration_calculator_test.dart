import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/user_profile.dart';
import 'package:my_app/services/hydration_calculator.dart';

void main() {
  test('calculates base hydration from weight', () {
    const profile = UserProfile(
      heightCm: 170,
      weightKg: 60,
      age: 30,
      activityIntensity: ActivityIntensity.none,
      pregnant: false,
      breastfeeding: false,
    );

    expect(HydrationCalculator.calculateDailyMl(profile), 2100);
  });

  test('applies age, activity, pregnancy and breastfeeding adjustments', () {
    const profile = UserProfile(
      heightCm: 165,
      weightKg: 70,
      age: 66,
      activityIntensity: ActivityIntensity.strong,
      pregnant: true,
      breastfeeding: true,
    );

    expect(HydrationCalculator.calculateDailyMl(profile), 4128);
  });

  test('clamps minimum and maximum values', () {
    const minimumProfile = UserProfile(
      heightCm: 155,
      weightKg: 20,
      age: 20,
      activityIntensity: ActivityIntensity.none,
      pregnant: false,
      breastfeeding: false,
    );
    const maximumProfile = UserProfile(
      heightCm: 180,
      weightKg: 140,
      age: 25,
      activityIntensity: ActivityIntensity.strong,
      pregnant: true,
      breastfeeding: true,
    );

    expect(HydrationCalculator.calculateDailyMl(minimumProfile), 1200);
    expect(HydrationCalculator.calculateDailyMl(maximumProfile), 5000);
  });
}
