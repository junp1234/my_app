import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../services/settings_repository.dart';
import '../widgets/droplet_button.dart';
import '../widgets/glass_gauge.dart';
import '../widgets/watery_background.dart';
import '../widgets/painters/glass_water_palette.dart';
import '../services/daily_totals_service.dart';
import '../services/water_log_service.dart';
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
  late final WaterLogService _waterLogService;
  Timer? _holdTimer;
  int _holdLevel = 1;
  bool _isHolding = false;

  late final AnimationController _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  late final AnimationController _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController _waterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final AnimationController _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _fullScaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  Tween<double> _waterLevelTween = Tween<double>(begin: 0, end: 0);
  bool _hasCelebratedFull = false;
  double _previousProgress = 0.0;
  double _backgroundTarget = 0.0;
  bool _celebrationRippleActive = false;
  final GlobalKey _glassKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _todayTotalMl = 0;
    _dailyGoalMl = 1500;
    _todayCount = 0;
    _canUndo = false;
    _waterCtrl.value = 0.0;
    _waterLevelTween = Tween<double>(begin: 0, end: 0);
    _rippleCtrl
      ..reset()
      ..stop();
    _shakeCtrl
      ..reset()
      ..stop();
    _fullScaleCtrl
      ..reset()
      ..stop();
    _maybeShowProfileOnFirstRun();
    _waterLogService = WaterLogService(widget.repository);
    debugPrint('HOME init: total=$_todayTotalMl goal=$_dailyGoalMl');
    unawaited(_initializeHomeState());
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
      _dailyGoalMl = widget.settings.dailyGoalMl;
      _syncWaterAnimation(animate: false, targetProgress: _computeProgress());
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
    _fullScaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeHomeState() async {
    final loadedSettings = await _settingsRepo.load();
    final todayTotal = await _waterLogService.getTodayTotal();
    final todayCount = await _waterLogService.getTodayCount();
    await _waterLogService.pruneOld();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = loadedSettings;
      _dailyGoalMl = loadedSettings.dailyGoalMl;
      _todayTotalMl = todayTotal;
      _todayCount = todayCount;
      _canUndo = _todayCount > 0;
      _syncWaterAnimation(animate: false, targetProgress: _computeProgress());
    });
    debugPrint('HOME total=$_todayTotalMl goal=$_dailyGoalMl progress=${_computeProgress()} undoCount=$todayCount');
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
      _canUndo = _todayCount > 0;
      _syncWaterAnimation(animate: animate, targetProgress: progress);
    });
    debugPrint('HOME total=$_todayTotalMl goal=$_dailyGoalMl progress=$progress undoCount=$count');
  }

  Future<void> _maybeShowProfileOnFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('profile_setup_done') ?? false;
    final skipped = prefs.getBool('profile_setup_skipped') ?? false;
    debugPrint('firstRun done=$done skipped=$skipped');

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
    _checkFullCelebration(targetProgress);
  }

  void _checkFullCelebration(double progress) {
    _backgroundTarget = progress == 1.0 ? 0.10 : 0.0;

    if (progress >= 1.0 && _previousProgress < 1.0 && !_hasCelebratedFull) {
      _hasCelebratedFull = true;
      _celebrationRippleActive = true;
      _fullScaleCtrl.forward(from: 0);
      HapticFeedback.mediumImpact();
      unawaited(
        _rippleCtrl.forward(from: 0).whenComplete(() {
          if (!mounted) {
            return;
          }
          setState(() {
            _celebrationRippleActive = false;
          });
        }),
      );
    } else if (progress < 1.0) {
      _hasCelebratedFull = false;
      _celebrationRippleActive = false;
    }
    _previousProgress = progress;
  }

  double get _bounceScale {
    final t = _fullScaleCtrl.value;
    if (t <= 0.5) {
      return 1.0 + (Curves.easeOutBack.transform(t / 0.5) * 0.03);
    }
    return 1.03 - (Curves.easeOut.transform((t - 0.5) / 0.5) * 0.03);
  }

  Future<void> _addWater() async {
    HapticFeedback.lightImpact();
    _pressCtrl.forward(from: 0);
    _dropCtrl.forward(from: 0);

    await Future<void>.delayed(const Duration(milliseconds: 280));
    HapticFeedback.selectionClick();

    final addMl = _settings.stepMl;
    await _waterLogService.add(addMl);
    await _refreshTodayState(animate: true);

    _rippleCtrl.forward(from: 0);
    _shakeCtrl.forward(from: 0);
  }

  Future<void> _undo() async {
    if (!_canUndo) {
      return;
    }

    final undone = await _waterLogService.undoLast();
    if (!undone) {
      return;
    }

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
    HapticFeedback.mediumImpact();
    await _refreshTodayState(animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final goal = _dailyGoalMl;
    final double progress = goal <= 0 ? 0.0 : (_todayTotalMl / goal).clamp(0.0, 1.0).toDouble();
    debugPrint('HOME total=$_todayTotalMl goal=$goal progress=$progress undoCount=$_todayCount');

    final pressScale = Tween<double>(begin: 1, end: 0.96).animate(_pressCtrl).value;
    final holdScale = _isHolding ? (0.9 + _holdLevel * 0.05) : 1.0;

    return Scaffold(
      body: Stack(
        children: [
          Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF2F2F7),
                      Color(0xFFFEFEFF),
                    ],
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                opacity: _backgroundTarget,
                child: WateryBackground(
                  tintColor: GlassWaterPalette.fullBackgroundTint(),
                ),
              ),
            ],
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
                    animation: Listenable.merge([_waterCtrl, _rippleCtrl, _shakeCtrl, _dropCtrl, _fullScaleCtrl]),
                    builder: (_, __) => GestureDetector(
                      onLongPress: _resetTodayTotal,
                      child: Stack(
                        key: _glassKey,
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: _bounceScale,
                            child: GlassGauge(
                              progress: _animatedWaterLevel,
                              rippleT: _rippleCtrl.value,
                              shakeT: _shakeCtrl.value,
                              dropT: _dropCtrl.value,
                              extraRippleLayer: _celebrationRippleActive,
                            ),
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
        ],
      ),
    );
  }
}
