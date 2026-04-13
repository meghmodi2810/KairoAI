import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS can bootstrap from GoogleService-Info.plist when available.
        await Firebase.initializeApp();
      } else {
        rethrow;
      }
    }
  }

  // Install App Check provider so Firebase services can request valid attestations.
  // Debug builds use debug providers to keep local development working.
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  } catch (e) {
    debugPrint('App Check activation failed: $e');
  }

  runApp(const MyApp());
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
