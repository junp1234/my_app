enum ActivityIntensity { none, light, normal, strong }

class UserProfile {
  const UserProfile({
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.activityIntensity,
    required this.pregnant,
    required this.breastfeeding,
  });

  final double heightCm;
  final double weightKg;
  final int age;
  final ActivityIntensity activityIntensity;
  final bool pregnant;
  final bool breastfeeding;

  static const defaults = UserProfile(
    heightCm: 160,
    weightKg: 55,
    age: 30,
    activityIntensity: ActivityIntensity.none,
    pregnant: false,
    breastfeeding: false,
  );

  UserProfile copyWith({
    double? heightCm,
    double? weightKg,
    int? age,
    ActivityIntensity? activityIntensity,
    bool? pregnant,
    bool? breastfeeding,
  }) {
    return UserProfile(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      activityIntensity: activityIntensity ?? this.activityIntensity,
      pregnant: pregnant ?? this.pregnant,
      breastfeeding: breastfeeding ?? this.breastfeeding,
    );
  }
}
