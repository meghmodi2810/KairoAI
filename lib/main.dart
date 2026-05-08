import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Launch the UI immediately — don't block on audio/notification setup
  runApp(const MyApp());

  // Initialize non-critical services in parallel, after the first frame
  Future.wait([
    AudioService().init(),
    NotificationService().init(),
  ]);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// Global access so any widget can toggle theme without InheritedWidget.
  static final ThemeProvider themeProvider = ThemeProvider();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    MyApp.themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    MyApp.themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: MyApp.themeProvider.themeMode,
      home: const AuthWrapper(),
    );
  }
}
