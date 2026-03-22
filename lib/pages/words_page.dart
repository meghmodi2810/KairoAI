import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'word_group_detail_page.dart';

class WordsPage extends StatelessWidget {
  const WordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: context.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: context.surface,
            pinned: false, floating: true,
            automaticallyImplyLeading: false,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Word Groups', style: TextStyle(
                          color: context.textPrimary, fontSize: 24,
                          fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                        // Gem balance chip
                        if (uid != null)
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users').doc(uid).snapshots(),
                            builder: (context, snap) {
                              final data = snap.data?.data() as Map<String, dynamic>?;
                              final gems = (data?['gems'] ?? 0) as int;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.purple.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.diamond_rounded, color: AppTheme.purple, size: 15),
                                  const SizedBox(width: 5),
                                  Text('$gems', style: const TextStyle(
                                    color: AppTheme.purple, fontSize: 13, fontWeight: FontWeight.w700)),
                                ]),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Practice vocabulary by signing words.', style: TextStyle(
                      color: context.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

          // ── Word groups ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('wordGroups')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.accent)));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.text_fields_rounded, color: context.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('No word groups yet', style: TextStyle(
                        color: context.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Word groups will appear here once added.',
                        style: TextStyle(color: context.textMuted, fontSize: 13),
                        textAlign: TextAlign.center),
                    ])));
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final doc  = snap.data!.docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return _WordGroupCard(
                        id: doc.id,
                        name: data['name'] ?? '',
                        iconEmoji: data['iconEmoji'] ?? '📝',
                        difficulty: data['difficulty'] ?? 'beginner',
                        totalWords: (data['totalWords'] ?? 0) as int,
                        gemCost: (data['gemCost'] ?? 0) as int,
                        isLocked: (data['isLocked'] ?? false) as bool,
                        uid: uid,
                      );
                    },
                    childCount: snap.data!.docs.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  Word group card — uses raw data, no model import
// ────────────────────────────────────────────────
class _WordGroupCard extends StatelessWidget {
  final String id;
  final String name;
  final String iconEmoji;
  final String difficulty;
  final int totalWords;
  final int gemCost;
  final bool isLocked;
  final String? uid;

  const _WordGroupCard({
    required this.id,
    required this.name,
    required this.iconEmoji,
    required this.difficulty,
    required this.totalWords,
    required this.gemCost,
    required this.isLocked,
    required this.uid,
  });

  Color _diffColor() {
    switch (difficulty.toLowerCase()) {
      case 'beginner':     return AppTheme.success;
      case 'intermediate': return AppTheme.warning;
      case 'advanced':     return AppTheme.danger;
      default:             return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _diffColor();

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showUnlockDialog(context);
          return;
        }
        // Navigate — pass raw data as a simple detail page
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => WordGroupDetailPage(
            groupId: id,
            groupName: name,
            iconEmoji: iconEmoji,
            difficulty: difficulty,
            totalWords: totalWords,
          )));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + gem badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? context.border
                        : AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isLocked
                        ? Icon(Icons.lock_rounded, color: context.textMuted, size: 20)
                        : Text(iconEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.purple.withOpacity(0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.diamond_rounded, color: AppTheme.purple, size: 12),
                      const SizedBox(width: 3),
                      Text('$gemCost', style: const TextStyle(
                        color: AppTheme.purple, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ],
            ),
            const Spacer(),
            Text(name, style: TextStyle(
              color: isLocked ? context.textMuted : context.textPrimary,
              fontSize: 15, fontWeight: FontWeight.w700),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: Text(difficulty, style: TextStyle(
                  color: diffColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text('$totalWords', style: TextStyle(
                color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Text('words', style: TextStyle(color: context.textMuted, fontSize: 11)),
            ]),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.border)),
        title: const Text('Unlock Word Group',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text('This group costs $gemCost 💎 gems to unlock.',
          style: TextStyle(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (uid == null) return;
              try {
                final fs = FirebaseFirestore.instance;
                await fs.runTransaction((txn) async {
                  final userRef  = fs.collection('users').doc(uid);
                  final groupRef = fs.collection('wordGroups').doc(id);
                  final userSnap = await txn.get(userRef);
                  final userGems = (userSnap.data()?['gems'] ?? 0) as int;
                  if (userGems < gemCost) throw Exception('Not enough gems.');
                  txn.update(userRef,  {'gems': userGems - gemCost});
                  txn.update(groupRef, {'isLocked': false});
                });
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Unlock for $gemCost 💎')),
        ],
      ),
    );
  }
}
