import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'sign_practice_page.dart';

class WordGroupDetailPage extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String iconEmoji;
  final String difficulty;
  final int totalWords;

  const WordGroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.iconEmoji,
    required this.difficulty,
    required this.totalWords,
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
    final diffColor = _difficultyColor();

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.warmWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.inkBlack, width: 3),
                          boxShadow: const [
                            BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(3, 3)),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: AppTheme.inkBlack),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NeoPanel(
                        color: AppTheme.electricBlue,
                        radius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Text(iconEmoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupName,
                                    style: const TextStyle(
                                      color: AppTheme.inkBlack,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalWords words',
                                    style: const TextStyle(
                                      color: AppTheme.inkBlack,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: diffColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.inkBlack, width: 2),
                              ),
                              child: Text(
                                difficulty.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.inkBlack,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('wordGroups')
                  .doc(groupId)
                  .collection('words')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.cobaltBlue)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: NeoEmptyState(
                      icon: Icons.text_fields,
                      title: 'No Words Yet',
                      subtitle: 'This pack is waiting for words.',
                    ),
                  );
                }

                return SliverList.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final word = (data['text'] ?? data['word'] ?? '') as String;
                    final hindi = data['wordInHindi'] as String?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeoPanel(
                        color: AppTheme.warmWhite,
                        radius: 16,
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.signalYellow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.inkBlack, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.inkBlack,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word,
                                    style: const TextStyle(
                                      color: AppTheme.inkBlack,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (hindi != null && hindi.isNotEmpty)
                                    Text(
                                      hindi,
                                      style: const TextStyle(
                                        color: AppTheme.inkBlack,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: word.isEmpty
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SignPracticePage(targetSign: word),
                                          ),
                                        ),
                                icon: const Icon(Icons.camera_alt, size: 16),
                                label: const Text('Practice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cobaltBlue,
                                  foregroundColor: AppTheme.warmWhite,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
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
