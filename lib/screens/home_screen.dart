import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/intake_repository.dart';
import '../models/app_settings.dart';
import '../models/intake_event.dart';
import '../widgets/glass_widget.dart';
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
  late final AnimationController _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final AnimationController _waterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final AnimationController _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

  double _fromProgress = 0;
  double _toProgress = 0;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    for (final controller in [_pressCtrl, _dropCtrl, _waterCtrl, _rippleCtrl, _shakeCtrl]) {
      controller.addListener(() {
        if (mounted) setState(() {});
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
    if (!mounted) return;
    setState(() => _todayTotal = total);
  }

  double get _progress => (_todayTotal / _settings.dailyGoalMl).clamp(0.0, 1.0);

  int _stepForLevel(int level) => switch (level) { 0 => (_settings.stepMl * 0.6).round(), 1 => _settings.stepMl, _ => (_settings.stepMl * 1.6).round() };

  Future<void> _addWater([int level = 1]) async {
    HapticFeedback.lightImpact();
    _pressCtrl.forward(from: 0);
    _dropCtrl.forward(from: 0);

    await Future<void>.delayed(const Duration(milliseconds: 210));
    HapticFeedback.selectionClick();

    final amount = _stepForLevel(level);
    final before = _progress;
    final event = await widget.repository.addEvent(amount);
    final afterTotal = await widget.repository.getTotalForDay(DateTime.now());

    if (!mounted) return;
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
      if (mounted) setState(() => _undoVisible = false);
    });
  }

  Future<void> _undo() async {
    final last = _lastEvent;
    if (last?.id == null || !_undoVisible) return;
    HapticFeedback.lightImpact();
    final before = _progress;
    await widget.repository.deleteEvent(last!.id!);
    final afterTotal = await widget.repository.getTotalForDay(DateTime.now());
    if (!mounted) return;
    setState(() {
      _todayTotal = afterTotal;
      _undoVisible = false;
      _fromProgress = before;
      _toProgress = _progress;
      _lastEvent = null;
    });
    _waterCtrl.forward(from: 0);
    _rippleCtrl.forward(from: 0.7);
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<AppSettings>(
      MaterialPageRoute(builder: (_) => SettingsScreen(initial: _settings)),
    );
    if (updated == null) return;
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
    final scale = Tween(begin: 1.0, end: 0.96).animate(_pressCtrl).value;
    final dropY = Tween(begin: -100.0, end: 70.0).animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.easeIn)).value;
    final dropOpacity = Tween(begin: 1.0, end: 0.2).animate(_dropCtrl).value;
    final shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 4), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 4, end: -3), weight: 45),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 30),
    ]).animate(_shakeCtrl).value;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2F2F7), Color(0xFFFCFCFF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(top: 6, left: 8, child: IconButton(onPressed: _openSettings, icon: const Icon(Icons.settings_outlined))),
              Positioned(top: 6, right: 8, child: IconButton(onPressed: _openHistory, icon: const Icon(Icons.access_time))),
              Center(
                child: Transform.translate(
                  offset: Offset(shakeX, 0),
                  child: GlassWidget(
                    progress: easedProgress,
                    ripple: _rippleCtrl.value,
                    activeDots: (14 * easedProgress).round(),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, -0.72),
                  child: GestureDetector(
                    onLongPressStart: (_) {
                      _isHolding = true;
                      _holdLevel = 0;
                      _holdTimer?.cancel();
                      _holdTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
                        if (!mounted || !_isHolding) return;
                        setState(() => _holdLevel = (_holdLevel + 1).clamp(0, 2));
                      });
                    },
                    onLongPressEnd: (_) {
                      _isHolding = false;
                      _holdTimer?.cancel();
                      _addWater(_holdLevel);
                    },
                    onTap: () => _addWater(1),
                    child: Transform.scale(
                      scale: _isHolding ? (0.88 + (_holdLevel * 0.08)) : scale,
                      child: const Icon(Icons.water_drop_rounded, color: Color(0xFF70BDF4), size: 84),
                    ),
                  ),
                ),
              ),
              if (_dropCtrl.isAnimating)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: const Alignment(0, -0.8),
                      child: Opacity(
                        opacity: dropOpacity,
                        child: Transform.translate(
                          offset: Offset(0, dropY),
                          child: const Icon(Icons.water_drop_rounded, color: Color(0xFF8DD4FF), size: 34),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_undoVisible)
                Positioned(
                  right: 24,
                  bottom: 40,
                  child: IconButton(
                    onPressed: _undo,
                    icon: const Icon(Icons.undo_rounded, color: Color(0x88707070)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
