import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'category_lessons_page.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LEARNING ROUTE',
                      style: TextStyle(
                        color: AppTheme.inkBlack,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Checkpoint by checkpoint. Hold your streak.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.inkBlack.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.cobaltBlue,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: NeoEmptyState(
                      icon: Icons.route,
                      title: 'No Learning Path Yet',
                      subtitle: 'Your admin will add categories here.',
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return SliverList.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final category = CategoryModel.fromFirestore(docs[index]);
                    final color = AppTheme
                        .categoryColors[index % AppTheme.categoryColors.length];
                    final isLast = index == docs.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 44,
                            child: Column(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: category.isLocked
                                        ? AppTheme.paperCream
                                        : color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.inkBlack,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    category.isLocked ? Icons.lock : Icons.flag,
                                    color: AppTheme.inkBlack,
                                    size: 14,
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 6,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.inkBlack,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                              child: _CategoryNode(
                                uid: uid,
                                category: category,
                                color: color,
                                onTap: category.isLocked
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CategoryLessonsPage(
                                            category: category,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryNode extends StatelessWidget {
  final String uid;
  final CategoryModel category;
  final Color color;
  final VoidCallback? onTap;

  const _CategoryNode({
    required this.uid,
    required this.category,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeoPanel(
        radius: 16,
        color: category.isLocked ? AppTheme.paperCream : AppTheme.warmWhite,
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: category.isLocked
                    ? AppTheme.paperCream
                    : color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppTheme.inkBlack, width: 2),
              ),
              child: Center(
                child: category.isLocked
                    ? const Icon(Icons.lock, color: AppTheme.inkBlack)
                    : (category.iconUrl != null && category.iconUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              category.iconUrl!,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                category.iconEmoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          )
                        : Text(
                            category.iconEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      color: AppTheme.inkBlack.withValues(
                        alpha: category.isLocked ? 0.5 : 1,
                      ),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    category.description,
                    style: const TextStyle(
                      color: AppTheme.inkBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .doc(category.id)
                        .collection('lessons')
                        .snapshots(),
                    builder: (context, lessonsSnapshot) {
                      final total =
                          lessonsSnapshot.data?.docs.length ??
                          category.totalLessons;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('progress')
                            .where('categoryId', isEqualTo: category.id)
                            .where('status', isEqualTo: 'completed')
                            .snapshots(),
                        builder: (context, progressSnapshot) {
                          final completed =
                              progressSnapshot.data?.docs.length ?? 0;
                          final progress = total > 0 ? completed / total : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: AppTheme.paperCream,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress == 1.0
                                        ? AppTheme.mintGreen
                                        : color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completed/$total lessons',
                                style: const TextStyle(
                                  color: AppTheme.inkBlack,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            if (!category.isLocked)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.inkBlack,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}
