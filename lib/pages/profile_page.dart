import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'login_page.dart';

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
          final level = (data?['level'] ?? 1) as int;
          final xp = (data?['xp'] ?? 0) as int;
          final streak = (data?['streakDays'] ?? 0) as int;
          final gems = (data?['gems'] ?? 0) as int;
          final signsLearned = (data?['totalSignsLearned'] ?? 0) as int;
          final lessonsCompleted = ((data?['completedLessonIds']) as List?)?.length ?? 0;

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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final email = FirebaseAuth.instance.currentUser?.email;
                              if (email != null && email.isNotEmpty) {
                                try {
                                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password reset email sent.'),
                                      backgroundColor: AppTheme.mintGreen,
                                    ),
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to send reset email.'),
                                      backgroundColor: AppTheme.punchRed,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.lock_reset_rounded),
                            label: const Text('Change Password'),
                          ),
                        ),
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
                    child: Column(
                      children: [
                        NeoPrimaryButton(
                          label: 'Need Help',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Help and support will be available soon.')),
                            );
                          },
                          icon: Icons.help_outline,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.paperCream,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: AppTheme.inkBlack, width: 3),
                                  ),
                                  title: const Text(
                                    'Log Out',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.inkBlack),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to log out?',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkBlack),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: AppTheme.inkBlack, fontWeight: FontWeight.bold)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.punchRed,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseAuth.instance.signOut();
                                if (!context.mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                  (_) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.punchRed,
                              foregroundColor: AppTheme.warmWhite,
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Log out'),
                          ),
                        ),
                      ],
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
