import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid  = FirebaseAuth.instance.currentUser?.uid ?? '';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: context.surface,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          final ud     = snap.data?.data() as Map<String, dynamic>?;
          final name   = (ud?['displayName'] ?? user?.displayName ?? 'Learner') as String;
          final email  = user?.email ?? '';
          final streak = (ud?['streakDays'] ?? 0) as int;
          final gems   = (ud?['gems']       ?? 0) as int;
          final xp     = (ud?['xp']         ?? 0) as int;
          final level  = (ud?['level']       ?? 1) as int;
          final completedLessons = ((ud?['completedLessonIds']) as List?)?.length ?? 0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO HEADER ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(name: name, email: email, level: level),
              ),

              // ── 2×2 STATS GRID ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: _StatCard(label: 'Day Streak', value: '$streak', emoji: '🔥',
                        color: const Color(0xFFFF6B35))),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Total XP', value: '$xp', emoji: '⚡',
                        color: AppTheme.warning)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _StatCard(label: 'Gems', value: '$gems', emoji: '💎',
                        color: AppTheme.purple)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Lessons', value: '$completedLessons', emoji: '📚',
                        color: AppTheme.accent)),
                    ]),
                  ]),
                ),
              ),

              // ── SETTINGS ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Settings', style: TextStyle(
                      color: context.textMuted, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    _SettingsGroup(items: [
                      _SettingsItemData(icon: Icons.person_rounded,      label: 'Account',        sub: email),
                      _SettingsItemData(icon: Icons.notifications_rounded, label: 'Notifications',   sub: 'Manage alerts'),
                      _SettingsItemData(icon: Icons.language_rounded,     label: 'Language',       sub: 'English'),
                    ]),
                    const SizedBox(height: 16),
                    Text('Support', style: TextStyle(
                      color: context.textMuted, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    _SettingsGroup(items: [
                      _SettingsItemData(icon: Icons.help_outline_rounded, label: 'Help & FAQ',     sub: 'Get support'),
                      _SettingsItemData(icon: Icons.info_outline_rounded, label: 'About KairoAI', sub: 'Version 1.0'),
                    ]),
                  ]),
                ),
              ),

              // ── SIGN OUT ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (_) => false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
                        const SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(
                          color: AppTheme.danger, fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
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
}

// ── Hero header ───────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String name, email;
  final int level;
  const _HeroHeader({required this.name, required this.email, required this.level});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent.withOpacity(0.7), AppTheme.accentDark.withOpacity(0.9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(children: [
        // Avatar
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Center(child: Text(initials.isEmpty ? '?' : initials,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(email, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
        const SizedBox(height: 12),
        // Level pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25))),
          child: Text('Level $level ISL Learner', style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── 2-col stat card ───────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border)),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.w900,
            letterSpacing: -0.5)),
          Text(label, style: TextStyle(color: context.textMuted, fontSize: 11)),
        ])),
      ]),
    );
  }
}

// ── Settings group ────────────────────────────────────────────
class _SettingsItemData {
  final IconData icon;
  final String label;
  final String? sub;
  const _SettingsItemData({required this.icon, required this.label, this.sub});
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItemData> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border)),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i    = e.key;
          final item = e.value;
          return Column(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, color: AppTheme.accent, size: 18)),
              title: Text(item.label, style: TextStyle(
                color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: item.sub != null
                  ? Text(item.sub!, style: TextStyle(color: context.textMuted, fontSize: 12))
                  : null,
              trailing: Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 18),
              dense: true,
            ),
            if (i < items.length - 1)
              Divider(height: 0, color: context.border, indent: 68),
          ]);
        }).toList(),
      ),
    );
  }
}
