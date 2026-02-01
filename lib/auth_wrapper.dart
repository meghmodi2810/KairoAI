import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'main_navigation.dart';
import 'admin/pages/admin_dashboard_page.dart';
import 'admin/models/admin_models.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _onboardingComplete = false;
  
  static const Color primaryBlue = Color(0xFF1A2151);
  static const Color darkBlue = Color(0xFF141938);

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
      return null; // Return null on error - user will be treated as regular learner
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryBlue, darkBlue],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      'assets/logo/logo.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: primaryBlue,
                          child: const Icon(
                            Icons.sign_language,
                            size: 60,
                            color: Color(0xFFFFD93D),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'KairoAI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD93D)),
                ),
              ],
            ),
          ),
        ),
      );
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
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryBlue, darkBlue],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD93D)),
                ),
              ),
            ),
          );
        }

        // User is logged in - check if admin or learner
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot?>(
            future: _checkAdminStatus(snapshot.data!.uid),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryBlue, darkBlue],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD93D)),
                      ),
                    ),
                  ),
                );
              }

              // Check if user is an admin
              if (adminSnapshot.hasData && adminSnapshot.data != null && adminSnapshot.data!.exists) {
                try {
                  final admin = AdminModel.fromFirestore(adminSnapshot.data!);
                  if (admin.isActive) {
                    return AdminDashboardPage(admin: admin);
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
