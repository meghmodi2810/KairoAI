import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'main_navigation.dart';
import 'package:kairo_ai/services/permission_bootstrap.dart';
import 'pages/post_login_experience_gate.dart';
import 'admin/screens/admin_shell.dart';
import 'admin/theme/admin_theme.dart';
import 'admin/models/admin_models.dart';
import 'services/database_service.dart';

enum _AuthDestination {
  admin,
  learner,
  inactiveAdmin,
  inactiveLearner,
  maintenance,
}

class _AuthDecision {
  final _AuthDestination destination;
  final AdminModel? admin;
  final String message;

  const _AuthDecision({
    required this.destination,
    this.admin,
    this.message = '',
  });
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  bool _onboardingComplete = false;

  static const Color ink = Color(0xFF111111);
  static const Color paper = Color(0xFFFFF7E8);
  static const Color blue = Color(0xFF58B9FF);
  static const Color yellow = Color(0xFFFFD84D);

  @override
  void initState() {
    super.initState();
    _requestInitialPermissions();
    _checkOnboardingStatus();
  }

  Future<void> _requestInitialPermissions() async {
    try {
      await PermissionBootstrap.requestInitialPermissions();
    } catch (e) {
      debugPrint('AuthWrapper: Permission bootstrap failed: $e');
    }
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
    return Theme(data: adminThemeLight(), child: child);
  }

  Widget _transitionPlaceholder() {
    return const Scaffold(backgroundColor: paper, body: SizedBox.expand());
  }

  Future<_AuthDecision> _resolveAuthDecision(User user) async {
    final uid = user.uid;

    final adminDoc = await _checkAdminStatus(uid);
    if (adminDoc != null && adminDoc.exists) {
      try {
        final admin = AdminModel.fromFirestore(adminDoc);
        if (admin.isActive) {
          return _AuthDecision(
            destination: _AuthDestination.admin,
            admin: admin,
          );
        }
        return const _AuthDecision(
          destination: _AuthDestination.inactiveAdmin,
          message:
              'Your admin account is currently inactive. Contact another admin for reactivation.',
        );
      } catch (e) {
        debugPrint('AuthWrapper: Failed to parse admin document: $e');
      }
    }

    try {
      await _db.createUserDocument(user);
    } catch (e) {
      debugPrint('AuthWrapper: Learner bootstrap failed: $e');
    }

    var learnerIsActive = true;
    try {
      final learnerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      learnerIsActive = (learnerDoc.data()?['isActive'] ?? true) == true;
    } catch (e) {
      debugPrint('AuthWrapper: Could not resolve learner status: $e');
    }

    if (!learnerIsActive) {
      return const _AuthDecision(
        destination: _AuthDestination.inactiveLearner,
        message:
            'This learner account has been deactivated. Please contact support.',
      );
    }

    try {
      final maintenanceDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('maintenance')
          .get();
      if (maintenanceDoc.exists) {
        final data = maintenanceDoc.data() ?? <String, dynamic>{};
        if ((data['isEnabled'] ?? false) == true) {
          return _AuthDecision(
            destination: _AuthDestination.maintenance,
            message:
                (data['message'] ??
                        'KairoAI is currently under maintenance. Please check back soon.')
                    .toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('AuthWrapper: Could not resolve maintenance mode: $e');
    }

    return const _AuthDecision(destination: _AuthDestination.learner);
  }

  Widget _blockedAccessScreen({
    required String title,
    required String body,
    required Color accent,
    bool showRefresh = false,
  }) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: ink, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: ink,
                        blurRadius: 0,
                        offset: Offset(8, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.block_rounded, color: ink, size: 56),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                if (showRefresh)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Check Again'),
                    ),
                  ),
                if (showRefresh) const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                      BoxShadow(
                        color: ink,
                        blurRadius: 0,
                        offset: Offset(8, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/logo/main_logo.png',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
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
                  height: 56,
                  child: Image.asset(
                    'assets/logo/auth_wrapper.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 20),
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
                        builder: (context, v, child) =>
                            Opacity(opacity: v, child: child),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: i.isEven ? yellow : blue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ink, width: 3),
                          ),
                          child: const Icon(
                            Icons.front_hand,
                            color: ink,
                            size: 20,
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
          return _transitionPlaceholder();
        }

        // User is logged in - check if admin or learner
        if (snapshot.hasData) {
          return FutureBuilder<_AuthDecision>(
            future: _resolveAuthDecision(snapshot.data!),
            builder: (context, decisionSnapshot) {
              if (decisionSnapshot.connectionState == ConnectionState.waiting) {
                return _transitionPlaceholder();
              }

              final decision = decisionSnapshot.data;
              if (decision == null) {
                return _transitionPlaceholder();
              }

              if (decision.destination == _AuthDestination.admin &&
                  decision.admin != null) {
                return _withAdminTheme(
                  context,
                  AdminShell(admin: decision.admin!),
                );
              }

              if (decision.destination == _AuthDestination.inactiveAdmin) {
                return _blockedAccessScreen(
                  title: 'Admin Access Blocked',
                  body: decision.message,
                  accent: yellow,
                );
              }

              if (decision.destination == _AuthDestination.inactiveLearner) {
                return _blockedAccessScreen(
                  title: 'Account Deactivated',
                  body: decision.message,
                  accent: const Color(0xFFFF9A76),
                );
              }

              if (decision.destination == _AuthDestination.maintenance) {
                return _blockedAccessScreen(
                  title: 'Maintenance Mode',
                  body: decision.message,
                  accent: blue,
                  showRefresh: true,
                );
              }

              // Regular learner - gate post-login tour and first lesson activation.
              return PostLoginExperienceGate(
                builder: (controller) => MainNavigation(controller: controller),
              );
            },
          );
        }

        // User is not logged in
        return const LoginPage();
      },
    );
  }
}
