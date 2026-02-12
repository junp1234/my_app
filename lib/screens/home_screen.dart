import 'dart:async';
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
  int _todayTotalMl = 0;
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
    _refreshTodayFromDb(animate: false);
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

  int get _visualMaxMl => (_settings.dailyGoalMl * 1.25).round();

  double get _displayProgress => (_todayTotalMl / _visualMaxMl).clamp(0.0, 1.0).toDouble();

  bool get _achieved => _todayTotalMl >= _settings.dailyGoalMl;

  double get _animatedWaterLevel => _waterLevelTween.transform(Curves.easeOut.transform(_waterCtrl.value));

  int _stepForLevel(int level) => switch (level) {1 => _settings.stepMl, 2 => _settings.stepMl * 2, _ => _settings.stepMl * 3};

  Future<void> _refreshTodayFromDb({bool animate = true}) async {
    final total = await widget.repository.sumTodayMl();
    final latest = await widget.repository.fetchLatestEventToday();
    if (!mounted) {
      return;
    }

    final visualMaxMl = (_settings.dailyGoalMl * 1.25).round();
    final targetProgress = (total / visualMaxMl).clamp(0.0, 1.0).toDouble();

    if (animate) {
      _waterLevelTween = Tween<double>(begin: _animatedWaterLevel, end: targetProgress);
      _waterCtrl
        ..reset()
        ..forward();
    } else {
      _waterLevelTween = Tween<double>(begin: targetProgress, end: targetProgress);
      _waterCtrl.value = 1.0;
    }

    setState(() {
      _todayTotalMl = total;
      _canUndo = latest != null;
    });
  }

  Future<void> _addWater([int level = 1]) async {
    HapticFeedback.lightImpact();
    _pressCtrl.forward(from: 0);
    _dropCtrl.forward(from: 0);

    await Future<void>.delayed(const Duration(milliseconds: 280));
    HapticFeedback.selectionClick();

    final amount = _stepForLevel(level);
    await widget.repository.addEvent(amount);
    await _refreshTodayFromDb(animate: true);

    _rippleCtrl.forward(from: 0);
    _shakeCtrl.forward(from: 0);
  }

  Future<void> _undo() async {
    if (!_canUndo) {
      return;
    }

    final ok = await widget.repository.undoLatestToday();
    if (!ok) {
      return;
    }

    HapticFeedback.selectionClick();
    await _refreshTodayFromDb(animate: true);
    debugPrint('undo -> total=$_todayTotalMl displayProgress=$_displayProgress achieved=$_achieved');

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
    setState(() => _settings = updated);
    await widget.onSettingsChanged(updated, askPermission);
    await _refreshTodayFromDb(animate: false);
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HistoryScreen(repository: widget.repository, settings: _settings)),
    );
    await _refreshTodayFromDb(animate: false);
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
                child: IconButton(onPressed: _openHistory, icon: const Icon(Icons.history)),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_waterCtrl, _rippleCtrl, _shakeCtrl, _dropCtrl]),
                  builder: (_, __) => GlassGauge(
                    progress: _animatedWaterLevel,
                    rippleT: _rippleCtrl.value,
                    shakeT: _shakeCtrl.value,
                    tickCount: 14,
                    dropT: _dropCtrl.value,
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
                      _addWater(_holdLevel);
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
