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
    stepMl: 200,
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
}
