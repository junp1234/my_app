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
import '../widgets/drop_shot_overlay.dart';
import '../widgets/overlays/soap_bubbles_overlay.dart';
import '../widgets/droplet_button.dart';
import '../widgets/glass_gauge.dart';
import '../widgets/painters/glass_fallback_ring_painter.dart';
import '../widgets/painters/water_fill_painter.dart';
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
  static const double _glassSize = 272;

  final _settingsRepo = SettingsRepository.instance;
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _dropletKey = GlobalKey();
  final GlobalKey _glassKey = GlobalKey();

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
  late final AnimationController _dropCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _waterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));

  Tween<double> _waterLevelTween = Tween<double>(begin: 0, end: 0);
  Offset? _dropStart;
  Offset? _dropEnd;
  Offset? _rippleCenter;
  Rect? _glassRectInStack;
  bool _metricsUpdateQueued = false;
  int _metricsRetryCount = 0;
  static const int _maxMetricsRetryCount = 8;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _waterLogService = WaterLogService(widget.repository);
    _dropCtl.addStatusListener(_onDropStatusChanged);
    _maybeShowProfileOnFirstRun();
    unawaited(_initializeHomeState());
    _queueMetricsUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _queueMetricsUpdate();
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
    _queueMetricsUpdate();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pressCtrl.dispose();
    _dropCtl.removeStatusListener(_onDropStatusChanged);
    _dropCtl.dispose();
    _waterCtrl.dispose();
    _rippleCtrl.dispose();
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
      _dropEnd = _computeDropEnd(progress, _stackSize() ?? Size.zero) ?? _dropEnd;
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

    final metrics = _currentGlassMetrics(_animatedWaterLevel);
    if (metrics != null) {
      _rippleCenter = Offset(metrics.innerRect.center.dx, metrics.waterTopY + 4);
    }
    _rippleCtrl.forward(from: 0);
  }

  void _onDropStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    final splashCenter = _dropEnd;
    if (splashCenter == null) {
      return;
    }
    setState(() {
      _rippleCenter = splashCenter;
    });
    _rippleCtrl.forward(from: 0);
  }

  void _queueMetricsUpdate() {
    if (_metricsUpdateQueued || !mounted) {
      return;
    }
    _metricsUpdateQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metricsUpdateQueued = false;
      _updateGlassMetricsFromLayout();
    });
  }

  void _updateGlassMetricsFromLayout() {
    if (!mounted) {
      return;
    }

    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) {
      if (_metricsRetryCount < _maxMetricsRetryCount) {
        _metricsRetryCount += 1;
        _queueMetricsUpdate();
      }
      return;
    }

    _metricsRetryCount = 0;
    final nextGlassRect = Rect.fromCenter(
      center: stackBox.size.center(Offset.zero),
      width: _glassSize,
      height: _glassSize,
    );

    final nextDropStart = _computeDropStart(stackBox);
    final nextDropEnd = _computeDropEnd(_computeProgress(), stackBox.size, glassRect: nextGlassRect);

    if (_glassRectInStack == nextGlassRect && _dropStart == nextDropStart && _dropEnd == nextDropEnd) {
      return;
    }

    setState(() {
      _glassRectInStack = nextGlassRect;
      _dropStart = nextDropStart;
      _dropEnd = nextDropEnd;
    });
  }

  void _syncGlassRectWithLayout(Size size) {
    final nextGlassRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: _glassSize,
      height: _glassSize,
    );
    if (_glassRectInStack == nextGlassRect) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _glassRectInStack == nextGlassRect) {
        return;
      }
      setState(() {
        _glassRectInStack = nextGlassRect;
      });
    });
  }

  Offset? _computeDropStart(RenderBox stackBox) {
    final dropletBox = _dropletKey.currentContext?.findRenderObject() as RenderBox?;
    if (dropletBox == null || !dropletBox.hasSize || !stackBox.hasSize) {
      return null;
    }

    final stackTopLeftGlobal = stackBox.localToGlobal(Offset.zero);
    return _clampToScreen(
      dropletBox.localToGlobal(Offset(dropletBox.size.width / 2, dropletBox.size.height)) - stackTopLeftGlobal,
      stackBox.size,
    );
  }

  Offset? _computeDropEnd(double progress, Size stackSize, {Rect? glassRect}) {
    final glassMetrics = _currentGlassMetrics(progress, glassRect: glassRect);
    if (glassMetrics == null) {
      return null;
    }

    final clampedY = (glassMetrics.waterTopY + 3).clamp(
      glassMetrics.innerRect.top + 8,
      glassMetrics.innerRect.bottom - 8,
    );
    return _clampToScreen(
      Offset(glassMetrics.glassCenter.dx, clampedY.toDouble()),
      stackSize,
    );
  }

  _GlassWaterMetrics? _currentGlassMetrics(double progress, {Rect? glassRect}) {
    glassRect ??= _glassRectInStack;
    if (glassRect == null) {
      return null;
    }

    final center = glassRect.center;
    final bowlRadius = glassRect.width * 0.39;
    final outerRect = Rect.fromCircle(center: center, radius: bowlRadius);
    final innerRect = outerRect.deflate(11);
    final waterTopY = WaterFillPainter.waterTopYForProgress(innerRect, progress);
    final waterPath = WaterFillPainter.waterPathForProgress(innerRect, progress);

    return _GlassWaterMetrics(
      innerRect: innerRect,
      waterTopY: waterTopY,
      waterPath: waterPath,
      glassCenter: center,
      glassRadius: bowlRadius,
    );
  }

  Size? _stackSize() {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) {
      return null;
    }
    return stackBox.size;
  }

  Offset _clampToScreen(Offset point, Size size) {
    return Offset(
      point.dx.clamp(0.0, size.width),
      point.dy.clamp(0.0, size.height),
    );
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

    final addMl = _settings.stepMl;
    final nextTotal = _todayTotalMl + addMl;
    final nextCount = _todayCount + 1;
    final goal = _dailyGoalMl;
    final nextProgress = goal <= 0 ? 0.0 : (nextTotal / goal).clamp(0.0, 1.0).toDouble();

    _intakeHistory.add(addMl);
    await _waterLogService.add(addMl);
    if (!mounted) {
      return;
    }

    HapticFeedback.selectionClick();
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? start = _dropStart;
    Offset? end = _dropEnd;
    if (stackBox != null && stackBox.hasSize) {
      start = _computeDropStart(stackBox);
      end = _computeDropEnd(_animatedWaterLevel, stackBox.size);
    }

    setState(() {
      _todayTotalMl = nextTotal;
      _todayCount = nextCount;
      _canUndo = _intakeHistory.isNotEmpty;
      _dropStart = start;
      _dropEnd = end;
      _rippleCenter = end;
      _syncWaterAnimation(animate: true, targetProgress: nextProgress);
    });

    debugPrint('DROP start=$start end=$end');
    _dropCtl
      ..stop()
      ..forward(from: 0);

    _handleGoalCrossing(totalMl: nextTotal, goalMl: goal);
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
    final progress = _computeProgress();
    final pressScale = Tween<double>(begin: 1, end: 0.96).animate(_pressCtrl).value;
    final holdScale = _isHolding ? (0.9 + _holdLevel * 0.05) : 1.0;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(color: Colors.white),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _syncGlassRectWithLayout(Size(constraints.maxWidth, constraints.maxHeight));

                return Stack(
                  key: _stackKey,
                  clipBehavior: Clip.none,
                  children: [
                if (progress >= 1.0)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: SoapBubblesOverlay(),
                    ),
                  ),
                    Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_waterCtrl, _rippleCtrl]),
                        builder: (_, __) => GestureDetector(
                          key: _glassKey,
                          onLongPress: _resetTodayTotal,
                          child: SizedBox(
                            width: _glassSize,
                            height: _glassSize,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                GlassGauge(
                                  progress: _animatedWaterLevel,
                                  rippleT: _rippleCtrl.value,
                                  dropT: 0,
                                  size: _glassSize,
                                ),
                                Image.asset(
                                  'assets/images/glass_empty.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => CustomPaint(
                                    painter: const GlassFallbackRingPainter(),
                                  ),
                                ),
                                IgnorePointer(
                                  child: CustomPaint(
                                    painter: _GlassOutlinePainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Builder(
                      builder: (_) {
                        final metrics = _currentGlassMetrics(_animatedWaterLevel);
                        final rippleCenter = _rippleCenter;
                        if (metrics == null || rippleCenter == null || _animatedWaterLevel <= 0) {
                          return const SizedBox.shrink();
                        }
                        final waterBounds = Rect.fromLTRB(
                          metrics.innerRect.left,
                          metrics.waterTopY,
                          metrics.innerRect.right,
                          metrics.innerRect.bottom,
                        );

                        return RippleScreenOverlay(
                          burstT: _rippleCtrl.value,
                          waterPath: metrics.waterPath,
                          waterTopY: metrics.waterTopY,
                          waterBounds: waterBounds,
                          center: rippleCenter,
                        );
                      },
                    ),
                    Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.73),
                    child: DropletButton(
                      key: _dropletKey,
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
                    Positioned.fill(
                  child: IgnorePointer(
                    child: DropShotOverlay(
                      controller: _dropCtl,
                      start: _dropStart,
                      end: _dropEnd,
                    ),
                  ),
                ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outlineRect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width * 0.39,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawOval(outlineRect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassOutlinePainter oldDelegate) {
    return false;
  }
}

class _GlassWaterMetrics {
  const _GlassWaterMetrics({
    required this.innerRect,
    required this.waterTopY,
    required this.waterPath,
    required this.glassCenter,
    required this.glassRadius,
  });

  final Rect innerRect;
  final double waterTopY;
  final Path waterPath;
  final Offset glassCenter;
  final double glassRadius;
}
