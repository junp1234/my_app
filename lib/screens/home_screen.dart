import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../services/daily_totals_service.dart';
import '../services/settings_repository.dart';
import '../services/water_log_service.dart';
import '../theme/water_theme.dart';
import '../widgets/completed_overlay.dart';
import '../widgets/droplet_button.dart';
import '../widgets/glass_gauge.dart';
import '../widgets/ripple_screen_overlay.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.repository,
    required this.onSettingsChanged,
  });

  final AppSettings settings;
  final IntakeRepository repository;
  final Future<void> Function(AppSettings settings, bool askPermission) onSettingsChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _settingsRepo = SettingsRepository.instance;

  late AppSettings _settings;
  int _todayTotalMl = 0;
  int _dailyGoalMl = 1500;
  int _todayCount = 0;
  bool _canUndo = false;
  bool _wasGoalReached = false;
  final List<int> _intakeHistory = [];

  late final WaterLogService _waterLogService;
  Timer? _holdTimer;
  int _holdLevel = 1;
  bool _isHolding = false;

  late final AnimationController _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  late final AnimationController _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController _waterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final AnimationController _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _celebrationCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _celebrationCtrl.value = 0;
        if (mounted) {
          setState(() {});
        }
      }
    });

  Tween<double> _waterLevelTween = Tween<double>(begin: 0, end: 0);

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _waterLogService = WaterLogService(widget.repository);
    _maybeShowProfileOnFirstRun();
    unawaited(_initializeHomeState());
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
      _dailyGoalMl = widget.settings.dailyGoalMl;
      _syncWaterAnimation(animate: false, targetProgress: _computeProgress());
      _wasGoalReached = _todayTotalMl >= _dailyGoalMl;
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pressCtrl.dispose();
    _dropCtrl.dispose();
    _waterCtrl.dispose();
    _rippleCtrl.dispose();
    _shakeCtrl.dispose();
    _celebrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeHomeState() async {
    final loadedSettings = await _settingsRepo.load();
    final todayTotal = await _waterLogService.getTodayTotal();
    final todayCount = await _waterLogService.getTodayCount();
    final todayEvents = await widget.repository.getEventsForDay(DateTime.now());
    await _waterLogService.pruneOld();
    if (!mounted) {
      return;
    }

    _intakeHistory
      ..clear()
      ..addAll(todayEvents.map((e) => e.amountMl));

    final progress = loadedSettings.dailyGoalMl <= 0 ? 0.0 : (todayTotal / loadedSettings.dailyGoalMl).clamp(0.0, 1.0).toDouble();
    setState(() {
      _settings = loadedSettings;
      _dailyGoalMl = loadedSettings.dailyGoalMl;
      _todayTotalMl = todayTotal;
      _todayCount = todayCount;
      _canUndo = _intakeHistory.isNotEmpty;
      _syncWaterAnimation(animate: false, targetProgress: progress);
      _wasGoalReached = _todayTotalMl >= _dailyGoalMl;
    });
  }

  Future<void> _refreshTodayState({required bool animate}) async {
    final total = await _waterLogService.getTodayTotal();
    final count = await _waterLogService.getTodayCount();
    if (!mounted) {
      return;
    }

    final goal = _dailyGoalMl;
    final progress = goal <= 0 ? 0.0 : (total / goal).clamp(0.0, 1.0).toDouble();
    setState(() {
      _todayTotalMl = total;
      _todayCount = count;
      _canUndo = _intakeHistory.isNotEmpty;
      _syncWaterAnimation(animate: animate, targetProgress: progress);
    });

    _handleGoalCrossing(totalMl: total, goalMl: goal);
  }

  void _handleGoalCrossing({required int totalMl, required int goalMl}) {
    if (goalMl <= 0) {
      _wasGoalReached = false;
      return;
    }

    final nowReached = totalMl >= goalMl;
    if (!_wasGoalReached && nowReached) {
      final total = totalMl;
      final goal = goalMl;
      debugPrint('CELEBRATION start total=$total goal=$goal');
      _triggerGoalCelebration();
    }
    _wasGoalReached = nowReached;
  }

  void _triggerGoalCelebration() {
    HapticFeedback.mediumImpact();
    _waterLevelTween = Tween<double>(begin: _animatedWaterLevel, end: 1.0);
    _waterCtrl
      ..reset()
      ..forward();
    _rippleCtrl.forward(from: 0);
    _celebrationCtrl.forward(from: 0);
  }

  Future<void> _maybeShowProfileOnFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('profile_setup_done') ?? false;
    final skipped = prefs.getBool('profile_setup_skipped') ?? false;

    if (done || skipped || !mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen(isFirstRun: true)),
      );
      if (!mounted || changed != true) {
        return;
      }
      await _refreshTodayState(animate: false);
    });
  }

  double _computeProgress() {
    final goal = _dailyGoalMl;
    return goal <= 0 ? 0.0 : (_todayTotalMl / goal).clamp(0.0, 1.0).toDouble();
  }

  double get _animatedWaterLevel => _waterLevelTween.transform(Curves.easeOut.transform(_waterCtrl.value));

  void _syncWaterAnimation({required bool animate, required double targetProgress}) {
    if (animate) {
      _waterLevelTween = Tween<double>(begin: _animatedWaterLevel, end: targetProgress);
      _waterCtrl
        ..reset()
        ..forward();
    } else {
      _waterLevelTween = Tween<double>(begin: targetProgress, end: targetProgress);
      _waterCtrl.value = 0.0;
    }
  }

  Future<void> _addWater() async {
    HapticFeedback.lightImpact();
    _pressCtrl.forward(from: 0);
    _dropCtrl.forward(from: 0);

    await Future<void>.delayed(const Duration(milliseconds: 280));
    HapticFeedback.selectionClick();

    final addMl = _settings.stepMl;
    _intakeHistory.add(addMl);
    await _waterLogService.add(addMl);
    await _refreshTodayState(animate: true);

    _rippleCtrl.forward(from: 0);
    _shakeCtrl.forward(from: 0);
  }

  Future<void> _undo() async {
    if (_intakeHistory.isEmpty) {
      return;
    }

    final removedMl = _intakeHistory.removeLast();
    final undone = await _waterLogService.undoLast();
    if (!undone) {
      _intakeHistory.add(removedMl);
      return;
    }

    _todayTotalMl = math.max(0, _todayTotalMl - removedMl);
    await DailyTotalsService.setToday(math.max(0, _todayTotalMl));

    HapticFeedback.selectionClick();
    await _refreshTodayState(animate: true);
    _rippleCtrl.value = 0;
  }

  Future<void> _openProfile({bool isInitialSetup = false}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProfileScreen(isFirstRun: isInitialSetup)),
    );
    if (!mounted || saved != true) {
      return;
    }
    await _refreshTodayState(animate: false);
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HistoryScreen(repository: widget.repository, settings: _settings)),
    );
  }

  Future<void> _resetTodayTotal() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('今日の記録をリセットしますか？'),
        content: const Text('今日の飲水イベントをすべて削除します。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('リセット')),
        ],
      ),
    );

    if (shouldReset != true) {
      return;
    }

    await widget.repository.deleteTodayEvents();
    await DailyTotalsService.setToday(0);
    _intakeHistory.clear();
    _wasGoalReached = false;
    HapticFeedback.mediumImpact();
    await _refreshTodayState(animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final goal = _dailyGoalMl;
    final bool isCompleted = _todayTotalMl >= goal && goal > 0;

    final pressScale = Tween<double>(begin: 1, end: 0.96).animate(_pressCtrl).value;
    final holdScale = _isHolding ? (0.9 + _holdLevel * 0.05) : 1.0;

    final celebrationBurst = CurvedAnimation(
      parent: _celebrationCtrl,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
    ).value;
    final shouldShowCelebration = _celebrationCtrl.isAnimating || _celebrationCtrl.value > 0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isCompleted
                    ? const [
                        WaterTheme.deepWater,
                        WaterTheme.primaryWater,
                      ]
                    : const [
                        Color(0xFFF2F2F7),
                        Color(0xFFFEFEFF),
                      ],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _openHistory,
                        icon: const Icon(Icons.bar_chart_rounded),
                      ),
                      IconButton(
                        onPressed: _openProfile,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_waterCtrl, _rippleCtrl, _shakeCtrl, _dropCtrl, _celebrationCtrl]),
                    builder: (_, __) => GestureDetector(
                      onLongPress: _resetTodayTotal,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GlassGauge(
                            progress: _animatedWaterLevel,
                            rippleT: _rippleCtrl.value,
                            shakeT: _shakeCtrl.value,
                            dropT: _dropCtrl.value,
                            extraRippleLayer: celebrationBurst > 0.02,
                          ),
                          RippleScreenOverlay(
                            size: 272,
                            progress: _animatedWaterLevel,
                            burstT: celebrationBurst,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.73),
                    child: DropletButton(
                      scale: pressScale * holdScale,
                      isPressed: _pressCtrl.isAnimating || _isHolding,
                      onTap: _addWater,
                      onLongPressStart: (_) {
                        _isHolding = true;
                        _holdLevel = 1;
                        _holdTimer?.cancel();
                        _holdTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
                          if (!mounted || !_isHolding) {
                            return;
                          }
                          setState(() => _holdLevel = _holdLevel == 3 ? 1 : _holdLevel + 1);
                        });
                      },
                      onLongPressEnd: (_) {
                        _isHolding = false;
                        _holdTimer?.cancel();
                        _addWater();
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 180,
                  child: IgnorePointer(
                    ignoring: !_canUndo,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _canUndo ? 1 : 0.4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: _undo,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                            child: const Icon(Icons.undo_rounded, color: Color(0x88707070)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (shouldShowCelebration)
            CompletedOverlay(
              animation: _celebrationCtrl,
              waterColor: WaterTheme.deepBlue,
            ),
        ],
      ),
    );
  }
}
