import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
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
    return Scaffold(
      backgroundColor: context.surface,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing header ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: context.surface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accent.withOpacity(0.8), AppTheme.accentDark.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(iconEmoji,
                              style: const TextStyle(fontSize: 26))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(groupName, style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(difficulty, style: const TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Text('$totalWords words', style: TextStyle(
                                color: Colors.white.withOpacity(0.75), fontSize: 13)),
                            ]),
                          ])),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Words list ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('wordGroups')
                  .doc(groupId)
                  .collection('words')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.accent)));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.text_fields_rounded, color: context.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('No words yet', style: TextStyle(
                        color: context.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                    ])),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final doc  = snap.data!.docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final word  = (data['text'] ?? data['word'] ?? '') as String;
                      final hindi = data['wordInHindi'] as String?;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: context.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.border),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text('${i + 1}', style: const TextStyle(
                                  color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(word, style: TextStyle(
                                color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                              if (hindi != null && hindi.isNotEmpty)
                                Text(hindi, style: TextStyle(color: context.textSecondary, fontSize: 13)),
                            ])),
                            if (word.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                                color: AppTheme.accent,
                                onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => SignPracticePage(targetSign: word))),
                              ),
                          ]),
                        ),
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
