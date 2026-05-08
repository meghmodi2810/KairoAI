import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;

          final name = (data?['displayName'] ?? user?.displayName ?? 'Learner') as String;
          final email = user?.email ?? '';
          final xp = (data?['xp'] ?? 0) as int;
          final storedLevel = data?['currentLevel'];
          final level = (storedLevel is int && storedLevel > 0)
              ? storedLevel
              : DatabaseService.computeLevel(xp);
          final streak = (data?['streakDays'] ?? 0) as int;
          final gems = (data?['gems'] ?? 0) as int;
          final signsLearned = (data?['totalSignsLearned'] ?? 0) as int;
          final lessonsCompleted = (data?['totalLessonsCompleted'] ?? 0) as int;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: NeoPanel(
                      color: AppTheme.electricBlue,
                      radius: 18,
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppTheme.signalYellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.inkBlack, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                _initials(name),
                                style: const TextStyle(
                                  color: AppTheme.inkBlack,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          NeoSticker(
                            label: 'LEVEL $level',
                            icon: Icons.military_tech,
                            color: AppTheme.signalYellow,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'XP',
                              value: '$xp',
                              color: AppTheme.signalYellow,
                              icon: Icons.bolt,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              label: 'STREAK',
                              value: '$streak',
                              color: AppTheme.punchRed,
                              icon: Icons.local_fire_department,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'GEMS',
                              value: '$gems',
                              color: AppTheme.gemPurple,
                              icon: Icons.diamond,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              label: 'LESSONS',
                              value: '$lessonsCompleted',
                              color: AppTheme.mintGreen,
                              icon: Icons.school,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: NeoPanel(
                    color: AppTheme.warmWhite,
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LEARNER PASSPORT',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _infoRow('Signs learned', '$signsLearned signs'),
                        const SizedBox(height: 8),
                        _infoRow('Current tier', 'Level $level'),
                        const SizedBox(height: 8),
                        _infoRow('Support', 'Help and FAQ available'),
                        const SizedBox(height: 8),
                        _infoRow('Language', 'English'),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: NeoPanel(
                    color: AppTheme.warmWhite,
                    radius: 18,
                    child: NeoPrimaryButton(
                      label: 'Settings',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsPage()),
                        );
                      },
                      icon: Icons.settings_rounded,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.inkBlack,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeoPanel(
      color: AppTheme.warmWhite,
      radius: 16,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
