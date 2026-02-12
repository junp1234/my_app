import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../models/intake_event.dart';
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
  int _todayTotal = 0;
  IntakeEvent? _lastEvent;
  bool _undoVisible = false;
  Timer? _undoTimer;
  Timer? _holdTimer;
  int _holdLevel = 1;
  bool _isHolding = false;

  late final AnimationController _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  late final AnimationController _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController _waterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final AnimationController _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  double _fromProgress = 0;
  double _toProgress = 0;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    for (final controller in [_pressCtrl, _dropCtrl, _waterCtrl, _rippleCtrl, _shakeCtrl]) {
      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
    _refresh();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _holdTimer?.cancel();
    _pressCtrl.dispose();
    _dropCtrl.dispose();
    _waterCtrl.dispose();
    _rippleCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final total = await widget.repository.getTotalForDay(DateTime.now());
    if (!mounted) {
      return;
    }
    setState(() => _todayTotal = total);
  }

  double get _progressRaw => _todayTotal / _settings.dailyGoalMl;

  double get _progress => _progressRaw.clamp(0.0, 1.0).toDouble();

  int _stepForLevel(int level) => switch (level) {1 => _settings.stepMl, 2 => _settings.stepMl * 2, _ => _settings.stepMl * 3};

  Future<void> _addWater([int level = 1]) async {
    HapticFeedback.lightImpact();
    _pressCtrl.forward(from: 0);
    _dropCtrl.forward(from: 0);

    await Future<void>.delayed(const Duration(milliseconds: 280));
    HapticFeedback.selectionClick();

    final amount = _stepForLevel(level);
    final before = _progress;
    final event = await widget.repository.addEvent(amount);
    final afterTotal = await widget.repository.getTotalForDay(DateTime.now());

    if (!mounted) {
      return;
    }
    setState(() {
      _lastEvent = event;
      _todayTotal = afterTotal;
      _undoVisible = true;
      _fromProgress = before;
      _toProgress = _progress;
    });

    _waterCtrl.forward(from: 0);
    _rippleCtrl.forward(from: 0);
    _shakeCtrl.forward(from: 0);

    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _undoVisible = false);
      }
    });
  }

  Future<void> _undo() async {
    final last = _lastEvent;
    if (last?.id == null || !_undoVisible) {
      return;
    }

    HapticFeedback.lightImpact();
    final before = _progress;
    await widget.repository.deleteEvent(last!.id!);
    final afterTotal = await widget.repository.getTotalForDay(DateTime.now());

    if (!mounted) {
      return;
    }
    setState(() {
      _todayTotal = afterTotal;
      _undoVisible = false;
      _fromProgress = before;
      _toProgress = _progress;
      _lastEvent = null;
    });

    _waterCtrl.forward(from: 0);
    _rippleCtrl.forward(from: 0.8);
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
    await _refresh();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HistoryScreen(repository: widget.repository, settings: _settings)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final easedProgress = Tween(begin: _fromProgress, end: _toProgress).animate(CurvedAnimation(parent: _waterCtrl, curve: Curves.easeOut)).value;
    final pressScale = Tween<double>(begin: 1, end: 0.96).animate(_pressCtrl).value;
    final holdScale = _isHolding ? (0.9 + _holdLevel * 0.05) : 1;

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
                child: GlassGauge(
                  progress: easedProgress,
                  rippleT: _rippleCtrl.value,
                  shakeT: _shakeCtrl.value,
                  tickCount: 14,
                  dropT: _dropCtrl.value,
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
              if (_undoVisible)
                Positioned(
                  right: 20,
                  bottom: 36,
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
            ],
          ),
        ),
      ),
    );
  }
}
