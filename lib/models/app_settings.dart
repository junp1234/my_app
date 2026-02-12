class AppSettings {
  const AppSettings({
    required this.dailyGoalMl,
    required this.stepMl,
    required this.reminderEnabled,
    required this.wakeMinutes,
    required this.sleepMinutes,
    required this.intervalMinutes,
    this.soundEnabled = false,
  });

  final int dailyGoalMl;
  final int stepMl;
  final bool reminderEnabled;
  final int wakeMinutes;
  final int sleepMinutes;
  final int intervalMinutes;
  final bool soundEnabled;

  static const defaults = AppSettings(
    dailyGoalMl: 2000,
    stepMl: 50,
    reminderEnabled: false,
    wakeMinutes: 7 * 60,
    sleepMinutes: 23 * 60,
    intervalMinutes: 90,
    soundEnabled: false,
  );

  AppSettings copyWith({
    int? dailyGoalMl,
    int? stepMl,
    bool? reminderEnabled,
    int? wakeMinutes,
    int? sleepMinutes,
    int? intervalMinutes,
    bool? soundEnabled,
  }) {
    return AppSettings(
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      stepMl: stepMl ?? this.stepMl,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppSettings &&
        other.dailyGoalMl == dailyGoalMl &&
        other.stepMl == stepMl &&
        other.reminderEnabled == reminderEnabled &&
        other.wakeMinutes == wakeMinutes &&
        other.sleepMinutes == sleepMinutes &&
        other.intervalMinutes == intervalMinutes &&
        other.soundEnabled == soundEnabled;
  }

  @override
  int get hashCode => Object.hash(
        dailyGoalMl,
        stepMl,
        reminderEnabled,
        wakeMinutes,
        sleepMinutes,
        intervalMinutes,
        soundEnabled,
      );
}
