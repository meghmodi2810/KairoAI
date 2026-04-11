import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'main_navigation.dart';
import 'package:kairo_ai/main.dart';
import 'admin/screens/admin_shell.dart';
import 'admin/theme/admin_theme.dart';
import 'admin/models/admin_models.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _onboardingComplete = false;

  static const Color ink = Color(0xFF111111);
  static const Color paper = Color(0xFFFFF7E8);
  static const Color blue = Color(0xFF58B9FF);
  static const Color yellow = Color(0xFFFFD84D);

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (mounted) {
      setState(() {
        _onboardingComplete = onboardingComplete;
        _isLoading = false;
      });
    }
  }

  /// Check if user is an admin - handles permission errors gracefully
  Future<DocumentSnapshot?> _checkAdminStatus(String uid) async {
    try {
      debugPrint('AuthWrapper: Checking admin status for UID: $uid');
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();
      debugPrint('AuthWrapper: Admin doc exists: ${doc.exists}');
      return doc;
    } catch (e) {
      debugPrint('AuthWrapper: Admin check failed (permission denied?): $e');
      return null;
    }
  }

  Widget _withAdminTheme(BuildContext context, Widget child) {
    final isDark = MyApp.themeProvider.isDarkMode;
    return Theme(
      data: isDark ? adminThemeDark() : adminThemeLight(),
      child: child,
    );
  }

  Widget _loadingScreen() {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: ink, width: 4),
                    boxShadow: const [
                      BoxShadow(color: ink, blurRadius: 0, offset: Offset(8, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/logo/logo.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: blue,
                          child: Icon(
                            Icons.sign_language,
                            size: 64,
                            color: ink,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'KAIROAI',
                  style: TextStyle(
                    color: ink,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ink, width: 3),
                  ),
                  child: const Text(
                    'GET YOUR HANDS READY',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: 170,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      3,
                      (i) => TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.2, end: 1),
                        duration: Duration(milliseconds: 520 + (i * 120)),
                        curve: Curves.easeOut,
                        builder: (context, v, child) => Opacity(opacity: v, child: child),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: i.isEven ? yellow : blue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ink, width: 3),
                          ),
                          child: const Icon(Icons.front_hand, color: ink, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _loadingScreen();
    }

    // If onboarding is not complete, show onboarding
    if (!_onboardingComplete) {
      return const OnboardingPage();
    }

    // If onboarding is complete, check authentication status
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingScreen();
        }

        // User is logged in - check if admin or learner
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot?>(
            future: _checkAdminStatus(snapshot.data!.uid),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return _loadingScreen();
              }

              // Check if user is an admin
              if (adminSnapshot.hasData &&
                  adminSnapshot.data != null &&
                  adminSnapshot.data!.exists) {
                try {
                  final admin = AdminModel.fromFirestore(adminSnapshot.data!);
                  if (admin.isActive) {
                    return _withAdminTheme(
                      context,
                      AdminShell(admin: admin),
                    );
                  }
                } catch (e) {
                  debugPrint('Error parsing admin data: $e');
                }
              }

              // Regular user - go to main navigation
              return const MainNavigation();
            },
          );
        }

        // User is not logged in
        return const LoginPage();
      },
    );
  }
}
