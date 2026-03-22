import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import 'learn_page.dart';

class HomePageNew extends StatelessWidget {
  const HomePageNew({super.key});

  @override
  Widget build(BuildContext context) {
    final uid  = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {
            final ud  = userSnap.data?.data() as Map<String, dynamic>?;
            final name   = (ud?['displayName'] ?? 'Learner') as String;
            final first  = name.split(' ').first;
            final streak = (ud?['streakDays'] ?? 0) as int;
            final gems   = (ud?['gems']       ?? 0) as int;
            final coins  = (ud?['coins']      ?? 0) as int;
            final xp     = (ud?['xp']         ?? 0) as int;
            final level  = (ud?['level']       ?? 1) as int;
            final xpForNext = level * 100;
            final xpProgress = (xp % xpForNext) / xpForNext;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Greeting header ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(greeting, style: TextStyle(
                          color: context.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(first, style: TextStyle(
                          color: context.textPrimary, fontSize: 28,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ])),
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentDark]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('Lv $level', style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                  ),
                ),

                // ── BENTO GRID: stats ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(children: [
                      // Row 1: Streak (big) + Gems
                      Row(children: [
                        Expanded(flex: 3, child: _BentoCard(
                          label: 'Day Streak',
                          value: '$streak',
                          emoji: '🔥',
                          accent: const Color(0xFFFF6B35),
                          large: true,
                        )),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: Column(children: [
                          _BentoCard(label: 'Gems', value: '$gems', emoji: '💎',
                            accent: AppTheme.purple),
                          const SizedBox(height: 10),
                          _BentoCard(label: 'Coins', value: '$coins', emoji: '🪙',
                            accent: AppTheme.warning),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      // Row 2: XP progress bar card
                      _XPCard(xp: xp, level: level, progress: xpProgress, xpForNext: xpForNext),
                    ]),
                  ),
                ),

                // ── Continue learning card ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _ContinueCard(uid: uid),
                  ),
                ),

                // ── Category list ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Learning Paths', style: TextStyle(
                        color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                      GestureDetector(
                        onTap: () {},
                        child: Text('See all', style: TextStyle(
                          color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: _CategorySliver(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Bento stat card ───────────────────────────────────────────
class _BentoCard extends StatelessWidget {
  final String label, value, emoji;
  final Color accent;
  final bool large;

  const _BentoCard({
    required this.label, required this.value,
    required this.emoji, required this.accent, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: large ? 120 : 55,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: large
          ? Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: TextStyle(
                  color: accent, fontSize: 32, fontWeight: FontWeight.w900,
                  letterSpacing: -1)),
                Text(label, style: TextStyle(
                  color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ])
          : Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(value, style: TextStyle(
                  color: accent, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(label, style: TextStyle(
                  color: context.textMuted, fontSize: 10)),
              ])),
            ]),
    );
  }
}

// ── XP bar card ───────────────────────────────────────────────
class _XPCard extends StatelessWidget {
  final int xp, level, xpForNext;
  final double progress;
  const _XPCard({required this.xp, required this.level, required this.progress, required this.xpForNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text('⚡', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('$xp XP', style: TextStyle(
              color: AppTheme.warning, fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
          Text('Level $level  →  ${xp % xpForNext}/$xpForNext to Lv ${level + 1}',
            style: TextStyle(color: context.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: context.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.warning),
          ),
        ),
      ]),
    );
  }
}

// ── Continue card ─────────────────────────────────────────────
class _ContinueCard extends StatelessWidget {
  final String uid;
  const _ContinueCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('progress')
          .where('status', isEqualTo: 'in_progress')
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final hasInProgress = snap.hasData && snap.data!.docs.isNotEmpty;
        final data = hasInProgress
            ? snap.data!.docs.first.data() as Map<String, dynamic>
            : null;
        final lessonName = data?['lessonName'] as String? ?? 'Start Learning';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.accent.withOpacity(0.8), AppTheme.accentDark],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                blurRadius: 20, offset: const Offset(0, 8))]),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hasInProgress ? 'Continue' : 'Start Learning',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(lessonName, style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              if (hasInProgress)
                Text('Pick up where you left off →',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))
            ])),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28)),
          ]),
        );
      },
    );
  }
}

// ── Category sliver (vertical list) ──────────────────────────
class _CategorySliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final docs = snap.data!.docs;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final d    = docs[i].data() as Map<String, dynamic>;
              final name = d['name'] as String? ?? '';
              final desc = d['description'] as String? ?? '';
              final lessons = (d['totalLessons'] ?? 0) as int;
              final color = AppTheme.categoryColors[i % AppTheme.categoryColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(
                        d['iconEmoji'] as String? ?? '📚',
                        style: const TextStyle(fontSize: 24)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(
                        color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(desc, style: TextStyle(
                        color: context.textMuted, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text('$lessons lessons', style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w700))),
                  ]),
                ),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }
}
