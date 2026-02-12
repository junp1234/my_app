import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../widgets/droplet_button.dart';
import '../widgets/glass_gauge.dart';
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
  late AppSettings _settings;
  int _displayTotalMl = 0;
  bool _canUndo = false;
  Timer? _holdTimer;
  int _holdLevel = 1;
  bool _isHolding = false;

  late final AnimationController _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  late final AnimationController _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController _waterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final AnimationController _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  Tween<double> _waterLevelTween = Tween<double>(begin: 0, end: 0);

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _syncWaterAnimation(animate: false);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pressCtrl.dispose();
    _dropCtrl.dispose();
    _waterCtrl.dispose();
    _rippleCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  double get _displayProgress {
    final goal = math.max(_settings.dailyGoalMl, 1);
    final effectiveTotalForUi = math.min(_displayTotalMl, goal);
    return (effectiveTotalForUi / goal).clamp(0.0, 1.0).toDouble();
  }

  double get _animatedWaterLevel => _waterLevelTween.transform(Curves.easeOut.transform(_waterCtrl.value));

  void _syncWaterAnimation({required bool animate}) {
    final targetProgress = _displayProgress;
    if (animate) {
      _waterLevelTween = Tween<double>(begin: _animatedWaterLevel, end: targetProgress);
      _waterCtrl
        ..reset()
        ..forward();
    } else {
      _waterLevelTween = Tween<double>(begin: targetProgress, end: targetProgress);
      _waterCtrl.value = 1.0;
    }
  }

  Future<void> _addWater() async {
    HapticFeedback.lightImpact();
    _pressCtrl.forward(from: 0);
    _dropCtrl.forward(from: 0);

    await Future<void>.delayed(const Duration(milliseconds: 280));
    HapticFeedback.selectionClick();

    final addAmountMl = _settings.stepMl;
    await widget.repository.addEvent(addAmountMl);
    if (!mounted) {
      return;
    }

    setState(() {
      _displayTotalMl += addAmountMl;
      _canUndo = _displayTotalMl > 0;
      _syncWaterAnimation(animate: true);
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
      _syncWaterAnimation(animate: true);
    });

    _rippleCtrl.value = 0;
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<AppSettings>(
      MaterialPageRoute(builder: (_) => SettingsScreen(initial: _settings)),
    );
    if (updated == null) {
      return;
    }
    final askPermission = !_settings.reminderEnabled && updated.reminderEnabled;
    setState(() {
      _settings = updated;
      _syncWaterAnimation(animate: false);
    });
    await widget.onSettingsChanged(updated, askPermission);
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
      _syncWaterAnimation(animate: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pressScale = Tween<double>(begin: 1, end: 0.96).animate(_pressCtrl).value;
    final holdScale = _isHolding ? (0.9 + _holdLevel * 0.05) : 1.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2F2F7), Color(0xFFFEFEFF)],
          ),
        ),
        child: SafeArea(
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
                  animation: Listenable.merge([_waterCtrl, _rippleCtrl, _shakeCtrl, _dropCtrl]),
                  builder: (_, __) => GestureDetector(
                    onLongPress: _resetTodayTotal,
                    child: GlassGauge(
                      progress: _animatedWaterLevel,
                      rippleT: _rippleCtrl.value,
                      shakeT: _shakeCtrl.value,
                      tickCount: 14,
                      dropT: _dropCtrl.value,
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
      ),
    );
  }
}
