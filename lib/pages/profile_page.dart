import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _user;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription<UserModel?>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _databaseService.createUserDocument(currentUser);
      }
      _userSubscription = _databaseService.userStream().listen(
        (user) {
          if (mounted) setState(() { _user = user; _isLoading = false; _hasError = false; });
        },
        onError: (error) {
          if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = 'Failed to load profile data'; });
        },
      );
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = 'Failed to initialize profile'; });
    }
  }

  Future<void> _refreshUser() async {
    setState(() { _isLoading = true; _hasError = false; });
    await _initializeUser();
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Profile', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: cs.primary));

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
              const SizedBox(height: 16),
              Text(_errorMessage, style: TextStyle(color: cs.onSurface.withOpacity(0.6)), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: _refreshUser, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUser,
      color: cs.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: cs.surface,
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary, width: 2.5),
              ),
              child: _auth.currentUser?.photoURL != null
                  ? ClipOval(child: Image.network(_auth.currentUser!.photoURL!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, color: cs.onSurface.withOpacity(0.35), size: 44)))
                  : Icon(Icons.person, color: cs.onSurface.withOpacity(0.35), size: 44),
            ),
            const SizedBox(height: 14),
            Text(_user?.displayName ?? _auth.currentUser?.displayName ?? 'Learner', style: TextStyle(color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_user?.email ?? _auth.currentUser?.email ?? '', style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14)),
            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip('💎', '${_user?.gems ?? 0}', 'Gems', cs),
                _buildStatChip('🪙', '${_user?.coins ?? 0}', 'Coins', cs),
                _buildStatChip('🔥', '${_user?.streakDays ?? 0}', 'Streak', cs),
              ],
            ),
            const SizedBox(height: 20),

            // Progress
            _buildProgressCard(cs),
            const SizedBox(height: 16),

            // ── Appearance ──
            _buildMenuTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: MyApp.themeProvider.themeMode == ThemeMode.dark ? 'Dark mode' : 'Light mode',
              trailing: Switch.adaptive(
                value: MyApp.themeProvider.themeMode == ThemeMode.dark,
                onChanged: (_) => MyApp.themeProvider.toggleTheme(),
                activeColor: cs.primary,
              ),
              onTap: () => MyApp.themeProvider.toggleTheme(),
              cs: cs,
            ),
            _buildMenuTile(icon: Icons.help_outline, title: 'Help & Support', subtitle: 'Get help with the app', onTap: () {}, cs: cs),
            _buildMenuTile(icon: Icons.info_outline, title: 'About', subtitle: 'Learn about KairoAI', onTap: () {}, cs: cs),
            const SizedBox(height: 16),

            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String emoji, String value, String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.onSurface.withOpacity(0.06))),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.onSurface.withOpacity(0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Progress', style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _progressRow('Lessons Completed', '${_user?.totalLessonsCompleted ?? 0}', cs),
          _progressRow('Signs Learned', '${_user?.totalSignsLearned ?? 0}', cs),
          _progressRow('Practice Time', '${_user?.totalPracticeMinutes ?? 0} min', cs),
          _progressRow('Current Level', '${_user?.currentLevel ?? 1}', cs),
        ],
      ),
    );
  }

  Widget _progressRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurface.withOpacity(0.55), fontSize: 14)),
          Text(value, style: TextStyle(color: cs.primary, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required ColorScheme cs, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.onSurface.withOpacity(0.06))),
      child: ListTile(
        leading: Icon(icon, color: cs.primary, size: 22),
        title: Text(title, style: TextStyle(color: cs.onSurface, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 12)),
        trailing: trailing ?? Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.3), size: 20),
        onTap: onTap,
      ),
    );
  }
}
