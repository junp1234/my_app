import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'widgets/water_bubble_fill.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();

  runApp(const HydrationApp());
}

class HydrationApp extends StatelessWidget {
  const HydrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const HydrationHomePage(),
    );
  }
}

class HydrationHomePage extends StatefulWidget {
  const HydrationHomePage({super.key});

  @override
  State<HydrationHomePage> createState() => _HydrationHomePageState();
}

class _HydrationHomePageState extends State<HydrationHomePage>
    with TickerProviderStateMixin {
  final StorageService _storageService = StorageService.instance;

  int _goalMl = 2000;
  int _servingMl = 200;
  int _todayIntakeMl = 0;
  bool _goalCelebrated = false;

  late final AnimationController _dropletController;
  late final AnimationController _glassFillController;

  @override
  void initState() {
    super.initState();
    _dropletController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glassFillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadState();
  }

  @override
  void dispose() {
    _dropletController.dispose();
    _glassFillController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final data = await _storageService.loadHydrationState();
    if (!mounted) {
      return;
    }
    setState(() {
      _goalMl = data.goalMl;
      _servingMl = data.servingMl;
      _todayIntakeMl = data.todayIntakeMl;
      _goalCelebrated = _todayIntakeMl >= _goalMl;
    });

    await NotificationService.instance.schedulePeriodicDropReminder();
  }

  Future<void> _addWater() async {
    final before = _todayIntakeMl;
    final updated = await _storageService.addWater(servingMl: _servingMl);
    if (!mounted) {
      return;
    }

    _glassFillController
      ..reset()
      ..forward();
    _dropletController
      ..reset()
      ..forward();

    setState(() {
      _todayIntakeMl = updated;
    });

    final goalReachedNow = before < _goalMl && updated >= _goalMl;
    if (goalReachedNow && !_goalCelebrated) {
      _goalCelebrated = true;
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  double get _progress => (_todayIntakeMl / _goalMl).clamp(0, 1);

  String _plantByProgress(double p) {
    if (p < 0.2) {
      return '🌱';
    }
    if (p < 0.5) {
      return '🪴';
    }
    if (p < 1.0) {
      return '🌿';
    }
    return '🌳';
  }

  Future<void> _openSettings() async {
    int tmpGoal = _goalMl;
    int tmpServing = _servingMl;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚙️', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text('Goal: $tmpGoal ml'),
                  Slider(
                    min: 500,
                    max: 5000,
                    divisions: 45,
                    value: tmpGoal.toDouble(),
                    onChanged: (value) {
                      setModalState(() => tmpGoal = value.round());
                    },
                  ),
                  const SizedBox(height: 4),
                  Text('Per glass: $tmpServing ml'),
                  Slider(
                    min: 50,
                    max: 500,
                    divisions: 18,
                    value: tmpServing.toDouble(),
                    onChanged: (value) {
                      setModalState(() => tmpServing = value.round());
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await _storageService.saveSettings(
                          goalMl: tmpGoal,
                          servingMl: tmpServing,
                        );
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _goalMl = tmpGoal;
                          _servingMl = tmpServing;
                          _goalCelebrated = _todayIntakeMl >= _goalMl;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plant = _plantByProgress(_progress);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💧'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassTapRow(
                  progress: _progress,
                  fillAnimation: _glassFillController,
                  onTap: _addWater,
                ),
                const SizedBox(height: 24),
                WaterBubbleProgress(
                  progress: _progress,
                  dropletAnimation: _dropletController,
                  onTap: _addWater,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: 1 + (_progress * 0.08),
                        duration: const Duration(milliseconds: 300),
                        child: Text(plant, style: const TextStyle(fontSize: 70)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).round()}%',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text('$_todayIntakeMl / $_goalMl ml'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassTapRow extends StatelessWidget {
  const GlassTapRow({
    required this.progress,
    required this.fillAnimation,
    required this.onTap,
    super.key,
  });

  final double progress;
  final Animation<double> fillAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const totalGlasses = 8;
    final filledGlasses = (progress * totalGlasses).floor();

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List.generate(totalGlasses, (index) {
          final isFilled = index < filledGlasses;

          return GestureDetector(
            onTap: onTap,
            child: AnimatedBuilder(
              animation: fillAnimation,
              builder: (context, _) {
                final dynamicFill = index == filledGlasses
                    ? fillAnimation.value
                    : (isFilled ? 1.0 : 0.0);

                return SizedBox(
                  width: 34,
                  height: 48,
                  child: CustomPaint(
                    painter: GlassPainter(fillLevel: dynamicFill),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class GlassPainter extends CustomPainter {
  GlassPainter({required this.fillLevel});

  final double fillLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.blueGrey;

    final waterPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.lightBlue.withOpacity(0.55);

    final glassRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 2, size.width - 6, size.height - 4),
      const Radius.circular(6),
    );
    canvas.drawRRect(glassRect, borderPaint);

    final waterHeight = (size.height - 8) * fillLevel;
    final waterRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, size.height - 4 - waterHeight, size.width - 10, waterHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(waterRect, waterPaint);
  }

  @override
  bool shouldRepaint(covariant GlassPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel;
  }
}

class WaterBubbleProgress extends StatefulWidget {
  const WaterBubbleProgress({
    required this.progress,
    required this.child,
    required this.dropletAnimation,
    this.onTap,
    super.key,
  });

  final double progress;
  final Widget child;
  final Animation<double> dropletAnimation;
  final VoidCallback? onTap;

  @override
  State<WaterBubbleProgress> createState() => _WaterBubbleProgressState();
}

class _WaterBubbleProgressState extends State<WaterBubbleProgress>
    with SingleTickerProviderStateMixin {
  final GlobalKey<WaterBubbleFillState> _bubbleFillKey =
      GlobalKey<WaterBubbleFillState>();
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onTap() {
    _bubbleFillKey.currentState?.triggerWobble();
    _shakeController
      ..reset()
      ..forward();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, _) {
          final wobble = sin(_shakeController.value * pi * 8) *
              (1 - _shakeController.value) *
              5;

          return Transform.translate(
            offset: Offset(wobble, 0),
            child: SizedBox(
              width: 220,
              height: 220,
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: WaterBubbleFill(
                        key: _bubbleFillKey,
                        progress: progress,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.lightBlue.shade300,
                          width: 5,
                        ),
                      ),
                    ),
                    DropletBurstOverlay(controller: widget.dropletAnimation),
                    Center(child: widget.child),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DropletBurstOverlay extends StatelessWidget {
  const DropletBurstOverlay({required this.controller, super.key});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final random = Random(8);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          if (controller.value == 0) {
            return const SizedBox.shrink();
          }

          return Stack(
            children: List.generate(14, (index) {
              final angle = (index / 14) * pi * 2;
              final distance = controller.value * (50 + random.nextInt(45));
              final size = 6 - (controller.value * 3);
              final opacity = (1 - controller.value).clamp(0.0, 1.0);

              return Positioned(
                left: 110 + cos(angle) * distance,
                top: 110 + sin(angle) * distance,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
