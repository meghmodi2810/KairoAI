import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import 'login_page.dart';
import 'home_page.dart';

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

  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color cardBg = Color(0xFF252A5E);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _databaseService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
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

  void _seedData() async {
    setState(() => _isLoading = true);
    await _databaseService.seedInitialData();
    await _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentYellow))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: accentYellow, width: 3),
                    ),
                    child: _auth.currentUser?.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              _auth.currentUser!.photoURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: Colors.white60,
                                size: 50,
                              ),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.white60, size: 50),
                  ),
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    _user?.displayName ?? 'Learner',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('💎', '${_user?.gems ?? 0}', 'Gems'),
                      _buildStatCard('🪙', '${_user?.coins ?? 0}', 'Coins'),
                      _buildStatCard('🔥', '${_user?.streakDays ?? 0}', 'Streak'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Progress Stats
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  
                  // Menu Options
                  _buildMenuOption(
                    icon: Icons.sign_language,
                    title: 'Test ISL',
                    subtitle: 'Test Indian Sign Language detection',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  _buildMenuOption(
                    icon: Icons.cloud_download,
                    title: 'Load Sample Data',
                    subtitle: 'Seed categories and lessons',
                    onTap: _seedData,
                  ),
                  _buildMenuOption(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help with the app',
                    onTap: () {},
                  ),
                  _buildMenuOption(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Learn about KairoAI',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressRow('Lessons Completed', '${_user?.totalLessonsCompleted ?? 0}'),
          _buildProgressRow('Signs Learned', '${_user?.totalSignsLearned ?? 0}'),
          _buildProgressRow('Practice Time', '${_user?.totalPracticeMinutes ?? 0} min'),
          _buildProgressRow('Current Level', '${_user?.currentLevel ?? 1}'),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: accentYellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentYellow),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }
}
