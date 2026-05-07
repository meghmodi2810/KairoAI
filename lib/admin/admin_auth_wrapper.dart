import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_database_service.dart';
import 'admin_login_page.dart';
import 'screens/admin_shell.dart';
import 'models/admin_models.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';

class AdminAuthWrapper extends StatefulWidget {
  const AdminAuthWrapper({super.key});

  @override
  State<AdminAuthWrapper> createState() => _AdminAuthWrapperState();
}

class _AdminAuthWrapperState extends State<AdminAuthWrapper> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Minimal dramatic delay
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (!snapshot.hasData) {
          return const AdminLoginPage();
        }

        return FutureBuilder<bool>(
          future: _adminDbService.isAdmin(),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (adminSnapshot.data == true) {
              // Creating a dummy AdminModel since isAdmin doesn't return one
              final admin = AdminModel(
                id: snapshot.data!.uid,
                email: snapshot.data!.email ?? '',
                displayName: 'Admin',
                role: 'admin',
                permissions: [],
                isActive: true,
                createdAt: DateTime.now(),
                lastLoginAt: DateTime.now(),
              );
              return AdminShell(admin: admin);
            }

            return _buildAccessDenied();
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.charcoalNight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              transform: Matrix4.rotationZ(0.1),
              child: const NeoPanel(
                color: AppTheme.signalYellow,
                padding: EdgeInsets.all(32),
                child: Icon(Icons.security_rounded, size: 48, color: AppTheme.inkBlack),
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'BOOTING CONTROL ROOM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.signalYellow),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const NeoPanel(
                color: AppTheme.punchRed,
                padding: EdgeInsets.all(32),
                child: Icon(Icons.lock_person_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 40),
              const Text(
                'UNAUTHORIZED ACCESS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your current credentials do not have administrative clearance for this domain.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 48),
              NeoButton(
                label: 'RETURN TO SAFE ZONE', 
                color: AppTheme.inkBlack, 
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
