import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/intake_repository.dart';
import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  await NotificationService.instance.initialize();
  runApp(const DropGlassApp());
}

class DropGlassApp extends StatefulWidget {
  const DropGlassApp({super.key});

  @override
  State<DropGlassApp> createState() => _DropGlassAppState();
}

class _DropGlassAppState extends State<DropGlassApp> {
  final _settingsService = SettingsRepository.instance;
  final _repository = IntakeRepository();
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _settingsService.load();
    if (!mounted) return;
    setState(() => _settings = loaded);
    await NotificationService.instance.applySchedule(loaded);
  }

  Future<void> _saveSettings(AppSettings settings, bool askPermission) async {
    await _settingsService.save(settings);
    await NotificationService.instance.applySchedule(settings, requestPermissionIfNeeded: askPermission);
    if (mounted) {
      setState(() => _settings = settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DropGlass',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FB),
      ),
      home: settings == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : HomeScreen(settings: settings, repository: _repository, onSettingsChanged: _saveSettings),
    );
  }
}
