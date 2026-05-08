import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'word_group_detail_page.dart';
import '../services/database_service.dart';
import '../models/app_models.dart';

class WordsPage extends StatelessWidget {
  const WordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: NeoSectionTitle(
                  title: 'WORD PACKS',
                  subtitle: 'Unlock with gems. Practice by signing each word.',
                  trailing: uid == null
                      ? null
                      : StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                          builder: (context, snapshot) {
                            final data = snapshot.data?.data() as Map<String, dynamic>?;
                            final gems = (data?['gems'] ?? 0) as int;
                            return NeoSticker(
                              label: '$gems GEMS',
                              icon: Icons.diamond,
                              color: AppTheme.signalYellow,
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('word_groups')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.cobaltBlue)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final visibleDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final isActive = data['isActive'];
                  final isPublished = data['isPublished'];
                  final activeFlag = isActive is bool ? isActive : true;
                  final publishedFlag = isPublished is bool ? isPublished : true;
                  return activeFlag && publishedFlag;
                }).toList();

                if (visibleDocs.isEmpty) {
                  return SliverFillRemaining(
                    child: NeoEmptyState(
                      icon: Icons.text_fields,
                      title: 'No Word Packs Yet',
                      subtitle: 'Word packs will appear once content is published.',
                    ),
                  );
                }

                return StreamBuilder<List<WordGroupUnlockModel>>(
                  stream: DatabaseService().wordGroupUnlocksStream(),
                  builder: (context, unlockSnapshot) {
                    final unlockedGroupIds = unlockSnapshot.data?.map((u) => u.groupId).toSet() ?? {};

                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.83,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = visibleDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          final unlockCost = (data['unlockGemCost'] ?? data['gemCost'] ?? 0) as int;
                          final isLocked = unlockCost > 0 && !unlockedGroupIds.contains(doc.id);

                          return _WordGroupCard(
                            id: doc.id,
                            uid: uid,
                            name: data['name'] ?? '',
                            iconEmoji: data['iconEmoji'] ?? '📝',
                            difficulty: data['difficulty'] ?? 'beginner',
                            totalWords: (data['totalWords'] ?? 0) as int,
                            gemCost: unlockCost,
                            isLocked: isLocked,
                            colorSeed: AppTheme.categoryColors[index % AppTheme.categoryColors.length],
                          );
                        },
                        childCount: visibleDocs.length,
                      ),
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WordGroupCard extends StatelessWidget {
  final String id;
  final String name;
  final String iconEmoji;
  final String difficulty;
  final int totalWords;
  final int gemCost;
  final bool isLocked;
  final String? uid;
  final Color colorSeed;

  const _WordGroupCard({
    required this.id,
    required this.uid,
    required this.name,
    required this.iconEmoji,
    required this.difficulty,
    required this.totalWords,
    required this.gemCost,
    required this.isLocked,
    required this.colorSeed,
  });

  Color _difficultyColor() {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppTheme.mintGreen;
      case 'intermediate':
        return AppTheme.signalYellow;
      case 'advanced':
        return AppTheme.punchRed;
      default:
        return AppTheme.electricBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showUnlockDialog(context);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WordGroupDetailPage(
              groupId: id,
              groupName: name,
              iconEmoji: iconEmoji,
              difficulty: difficulty,
              totalWords: totalWords,
            ),
          ),
        );
      },
      child: NeoPanel(
        color: AppTheme.warmWhite,
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLocked ? AppTheme.paperCream : colorSeed.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.inkBlack, width: 2),
                  ),
                  child: Center(
                    child: isLocked
                        ? const Icon(Icons.lock, color: AppTheme.inkBlack)
                        : Text(iconEmoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                if (isLocked)
                  NeoSticker(
                    label: '$gemCost',
                    icon: Icons.diamond,
                    color: AppTheme.signalYellow,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              name,
              style: TextStyle(
                color: isLocked ? AppTheme.inkBlack.withValues(alpha: 0.65) : AppTheme.inkBlack,
                fontSize: 17,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _difficultyColor(),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.inkBlack, width: 2),
                  ),
                  child: Text(
                    difficulty.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.inkBlack,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$totalWords words',
                  style: const TextStyle(
                    color: AppTheme.inkBlack,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unlock Pack?'),
        content: Text('This pack unlocks with $gemCost gems.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (uid == null) return;
              try {
                final success = await DatabaseService().unlockWordGroup(id, gemCost);
                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Pack unlocked. Gems deducted.')),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Not enough gems or unlock failed.')),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unlock failed. Please try again.')),
                );
              }
            },
            child: Text('Unlock for $gemCost'),
          ),
        ],
      ),
    );
  }
}
