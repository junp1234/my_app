import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../services/settings_repository.dart';
import '../widgets/droplet_button.dart';
import '../widgets/glass_gauge.dart';
import '../widgets/ripple_screen_overlay.dart';
import '../widgets/sparkle_overlay.dart';
import '../widgets/watery_background.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

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
  int _displayTotalMl = 0;
  int _todayPersistedTotalMl = 0;
  bool _canUndo = false;
  Timer? _holdTimer;
  int _holdLevel = 1;
  bool _isHolding = false;

  late final AnimationController _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  late final AnimationController _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController _waterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final AnimationController _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _fullScaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  late final AnimationController _fullRippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 980));

  Tween<double> _waterLevelTween = Tween<double>(begin: 0, end: 0);
  bool _hasCelebratedFull = false;
  double _previousProgress = 0.0;
  double _backgroundTarget = 0.0;
  bool _celebrationRippleActive = false;
  final GlobalKey _glassKey = GlobalKey();
  final GlobalKey _overlayKey = GlobalKey();
  Offset? _rippleCenter;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _displayTotalMl = 0;
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
    _sparkleCtrl
      ..reset()
      ..stop();
    _fullRippleCtrl
      ..reset()
      ..stop();
    debugPrint('HOME init: displayTotal=$_displayTotalMl goal=${_settings.dailyGoalMl}');
    unawaited(_initializeHomeState());
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
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
    _sparkleCtrl.dispose();
    _fullRippleCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeHomeState() async {
    final loadedSettings = await _settingsRepo.load();
    final todayTotal = await widget.repository.sumTodayMl();
    if (!mounted) {
      return;
    }
    _settings = loadedSettings;
    _todayPersistedTotalMl = todayTotal;
    _syncWaterAnimation(animate: false, targetProgress: _computeProgress());
    setState(() {});
    debugPrint('HOME persisted total loaded: $_todayPersistedTotalMl (UI display remains $_displayTotalMl)');
  }

  double _computeProgress() {
    final goal = _settings.dailyGoalMl;
    return goal <= 0 ? 0.0 : (_displayTotalMl / goal).clamp(0.0, 1.0).toDouble();
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
    _backgroundTarget = progress == 1.0 ? 1.0 : 0.0;

    if (progress >= 1.0 && _previousProgress < 1.0 && !_hasCelebratedFull) {
      _hasCelebratedFull = true;
      _celebrationRippleActive = true;
      _updateRippleCenter();
      _fullScaleCtrl.forward(from: 0);
      _sparkleCtrl.forward(from: 0);
      _fullRippleCtrl.forward(from: 0);
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

  void _updateRippleCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlayContext = _overlayKey.currentContext;
      final glassContext = _glassKey.currentContext;
      if (!mounted || overlayContext == null || glassContext == null) {
        return;
      }

      final overlayBox = overlayContext.findRenderObject() as RenderBox?;
      final glassBox = glassContext.findRenderObject() as RenderBox?;
      if (overlayBox == null || glassBox == null) {
        return;
      }

      final glassCenterGlobal = glassBox.localToGlobal(glassBox.size.center(Offset.zero));
      final center = overlayBox.globalToLocal(glassCenterGlobal);
      if (_rippleCenter == center) {
        return;
      }
      setState(() {
        _rippleCenter = center;
      });
    });
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
    await widget.repository.addEvent(addMl);
    if (!mounted) {
      return;
    }

    final nextTotal = _displayTotalMl + addMl;
    final goal = _settings.dailyGoalMl;
    final progress = goal <= 0 ? 0.0 : (nextTotal / goal).clamp(0.0, 1.0);
    debugPrint('tap add=$addMl displayTotal=$nextTotal goal=$goal progress=$progress');

    setState(() {
      _displayTotalMl = nextTotal;
      _canUndo = _displayTotalMl > 0;
      _syncWaterAnimation(animate: true, targetProgress: progress.toDouble());
    });

    _rippleCtrl.forward(from: 0);
    _shakeCtrl.forward(from: 0);
  }

  Future<void> _undo() async {
    if (!_canUndo) {
      return;
    }

    final latest = await widget.repository.fetchLatestEventToday();
    if (latest?.id == null) {
      return;
    }

    await widget.repository.deleteEventById(latest!.id!);
    if (!mounted) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _displayTotalMl = math.max(_displayTotalMl - latest.amountMl, 0);
      _canUndo = _displayTotalMl > 0;
      _syncWaterAnimation(animate: true, targetProgress: _computeProgress());
    });

    _rippleCtrl.value = 0;
  }

  Future<void> _openSettings() async {
    final previousSettings = _settings;
    final result = await Navigator.of(context).push<AppSettings>(
      MaterialPageRoute(builder: (_) => SettingsScreen(initial: _settings)),
    );
    if (!mounted) {
      return;
    }
    if (result != null) {
      final askPermission = !previousSettings.reminderEnabled && result.reminderEnabled;
      setState(() {
        _settings = result;
        _syncWaterAnimation(animate: false, targetProgress: _computeProgress());
      });
      await widget.onSettingsChanged(result, askPermission);
      return;
    }
    await _reloadSettings(previousSettings: previousSettings);
  }

  Future<void> _reloadSettings({required AppSettings previousSettings}) async {
    final reloaded = await _settingsRepo.load();
    final askPermission = !previousSettings.reminderEnabled && reloaded.reminderEnabled;
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = reloaded;
      _syncWaterAnimation(animate: false, targetProgress: _computeProgress());
    });
    await widget.onSettingsChanged(reloaded, askPermission);
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
    HapticFeedback.mediumImpact();
    if (!mounted) {
      return;
    }

    setState(() {
      _displayTotalMl = 0;
      _canUndo = false;
      _syncWaterAnimation(animate: true, targetProgress: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final goal = _settings.dailyGoalMl;
    final double progress = goal <= 0 ? 0.0 : (_displayTotalMl / goal).clamp(0.0, 1.0).toDouble();
    debugPrint('HOME build: displayTotal=$_displayTotalMl goal=$goal progress=$progress');

    final pressScale = Tween<double>(begin: 1, end: 0.96).animate(_pressCtrl).value;
    final sparkleProgress = _sparkleCtrl.value;
    final holdScale = _isHolding ? (0.9 + _holdLevel * 0.05) : 1.0;

    _updateRippleCenter();

    return Scaffold(
      body: Stack(
        key: _overlayKey,
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
                child: const WateryBackground(),
              ),
            ],
          ),
          SafeArea(
            child: Stack(
              children: [
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(onPressed: _openSettings, icon: const Icon(Icons.settings_outlined)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onLongPress: _resetTodayTotal,
                  child: IconButton(onPressed: _openHistory, icon: const Icon(Icons.history)),
                ),
              ),
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_waterCtrl, _rippleCtrl, _shakeCtrl, _dropCtrl, _fullScaleCtrl, _sparkleCtrl]),
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
                          Positioned.fill(
                            child: IgnorePointer(
                              child: SparkleOverlay(progress: sparkleProgress),
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
                  bottom: 36,
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
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fullRippleCtrl,
                builder: (_, __) => RippleScreenOverlay(
                  t: _fullRippleCtrl,
                  center: _rippleCenter,
                  enabled: _fullRippleCtrl.value > 0 && _fullRippleCtrl.value < 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
