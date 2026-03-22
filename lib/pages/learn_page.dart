import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'category_lessons_page.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: context.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Learn', style: TextStyle(
                    color: context.textPrimary, fontSize: 28,
                    fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                  const SizedBox(height: 2),
                  Text('Indian Sign Language — A to Z and numbers',
                    style: TextStyle(color: context.textMuted, fontSize: 13)),
                ]),
              ),
            ),
          ),

          // ── Category cards (path style) ─────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.accent)));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Text('No categories yet.',
                      style: TextStyle(color: context.textSecondary))));
                }

                final docs = snap.data!.docs;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final doc  = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final cat  = CategoryModel.fromFirestore(doc);
                      final color = AppTheme.categoryColors[i % AppTheme.categoryColors.length];
                      final isLast = i == docs.length - 1;

                      return Column(children: [
                        _CategoryNode(
                          index: i,
                          category: cat,
                          color: color,
                          uid: uid,
                          onTap: cat.isLocked
                              ? null
                              : () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => CategoryLessonsPage(category: cat))),
                        ),
                        if (!isLast) _PathConnector(color: color),
                      ]);
                    },
                    childCount: docs.length,
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

// ── Learning path node ────────────────────────────────────────
class _CategoryNode extends StatelessWidget {
  final int index;
  final CategoryModel category;
  final Color color;
  final String uid;
  final VoidCallback? onTap;

  const _CategoryNode({
    required this.index,
    required this.category,
    required this.color,
    required this.uid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index.isEven;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: isEven ? 0 : 48,
          right: isEven ? 48 : 0,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: category.isLocked ? context.card.withOpacity(0.5) : context.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: category.isLocked ? context.border : color.withOpacity(0.4),
              width: category.isLocked ? 1 : 1.5,
            ),
          ),
          child: Row(children: [
            // Icon container
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: category.isLocked
                    ? context.border
                    : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: category.isLocked
                    ? Icon(Icons.lock_rounded, color: context.textMuted, size: 24)
                    : Text(category.iconEmoji,
                        style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category.name,
                style: TextStyle(
                  color: category.isLocked ? context.textMuted : context.textPrimary,
                  fontSize: 16, fontWeight: FontWeight.w800),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(category.description,
                style: TextStyle(color: context.textMuted, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              // Progress bar inside the card
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users').doc(uid)
                    .collection('progress')
                    .where('categoryId', isEqualTo: category.id)
                    .where('status', isEqualTo: 'completed')
                    .snapshots(),
                builder: (context, pSnap) {
                  final completed = pSnap.data?.docs.length ?? 0;
                  final total = category.totalLessons;
                  final pct = total > 0 ? completed / total : 0.0;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: context.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pct == 1.0 ? AppTheme.success : color),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('$completed/${category.totalLessons} lessons',
                      style: TextStyle(color: context.textMuted, fontSize: 10)),
                  ]);
                },
              ),
            ])),
            // Arrow
            if (!category.isLocked)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.arrow_forward_ios_rounded,
                  color: color.withOpacity(0.6), size: 14)),
          ]),
        ),
      ),
    );
  }
}

// ── Path connector between nodes ──────────────────────────────
class _PathConnector extends StatelessWidget {
  final Color color;
  const _PathConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Center(
        child: Container(
          width: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.5), color.withOpacity(0.15)],
            ),
          ),
        ),
      ),
    );
  }
}
