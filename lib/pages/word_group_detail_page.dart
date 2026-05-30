import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/lesson_character_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'word_practice_page.dart';
import '../models/admin_models.dart';
import 'sign_learning_page.dart';

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
    final db = DatabaseService();

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
                          border: Border.all(
                            color: AppTheme.inkBlack,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.inkBlack,
                              blurRadius: 0,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NeoPanel(
                        color: AppTheme.electricBlue,
                        radius: 16,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Text(
                              iconEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: diffColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.inkBlack,
                                  width: 2,
                                ),
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
                  .collection('word_groups')
                  .doc(groupId)
                  .collection('words')
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
                      icon: Icons.text_fields,
                      title: 'No Words Yet',
                      subtitle: 'This pack is waiting for words.',
                    ),
                  );
                }

                return StreamBuilder<List<String>>(
                  stream: db.completedSignCharactersStream(),
                  builder: (context, completedSnapshot) {
                    final completed =
                        completedSnapshot.data ?? const <String>[];

                    return SliverList.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final wordModel = WordModel.fromFirestore(doc);
                        return _WordRow(
                          index: index,
                          groupId: groupId,
                          wordModel: wordModel,
                          completedCharacters: completed,
                        );
                      },
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

class _WordRow extends StatelessWidget {
  final int index;
  final String groupId;
  final WordModel wordModel;
  final List<String> completedCharacters;

  const _WordRow({
    required this.index,
    required this.groupId,
    required this.wordModel,
    required this.completedCharacters,
  });

  List<String> _requiredCharacters() {
    final explicit = wordModel.characters.map((character) => character.char);
    final normalizedExplicit = normalizeSignCharacters(explicit);
    if (normalizedExplicit.isNotEmpty) return normalizedExplicit;

    return normalizeSignCharacters(
      wordModel.normalizedText
          .split('')
          .where((character) => RegExp(r'^[A-Z0-9]$').hasMatch(character)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = wordModel.text;
    final required = _requiredCharacters();
    final prerequisite = buildWordPrerequisiteResult(
      requiredCharacters: required,
      completedCharacters: completedCharacters,
    );

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
                color: prerequisite.isReady
                    ? AppTheme.signalYellow
                    : AppTheme.paperCream,
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
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: required.map((character) {
                      final done = prerequisite.completedCharacters.contains(
                        character,
                      );
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: done ? AppTheme.mintGreen : AppTheme.softPeach,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.inkBlack,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          character,
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }).toList(),
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
                    : prerequisite.isReady
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WordPracticePage(
                            wordModel: wordModel,
                            groupId: groupId,
                          ),
                        ),
                      )
                    : () => _showMissingCharactersDialog(context, prerequisite),
                icon: Icon(
                  prerequisite.isReady ? Icons.camera_alt : Icons.lock_open,
                  size: 16,
                ),
                label: Text(prerequisite.isReady ? 'Practice' : 'Missing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: prerequisite.isReady
                      ? AppTheme.cobaltBlue
                      : AppTheme.signalYellow,
                  foregroundColor: prerequisite.isReady
                      ? AppTheme.warmWhite
                      : AppTheme.inkBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMissingCharactersDialog(
    BuildContext context,
    WordPrerequisiteResult prerequisite,
  ) async {
    final db = DatabaseService();
    final index = await db.buildLessonCandidatesForCharacters(
      prerequisite.missingCharacters,
    );
    if (!context.mounted) return;

    final candidates = index.rankedCandidatesFor(
      prerequisite.missingCharacters,
    );
    final selected = await showDialog<LessonCharacterCandidate>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Learn Missing Signs'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Missing: ${prerequisite.missingCharacters.join(', ')}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (candidates.isEmpty)
                  const Text('No lesson currently teaches these signs.')
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      separatorBuilder: (_, _) => const Divider(height: 12),
                      itemBuilder: (_, candidateIndex) {
                        final candidate = candidates[candidateIndex];
                        final covers =
                            candidate.characters
                                .intersection(prerequisite.missingCharacters)
                                .toList()
                              ..sort();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(candidate.lessonTitle),
                          subtitle: Text(
                            '${candidate.categoryName} - covers ${covers.join(', ')}',
                          ),
                          trailing: const Icon(Icons.arrow_forward_rounded),
                          onTap: () => Navigator.pop(dialogContext, candidate),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Not now'),
            ),
          ],
        );
      },
    );

    if (selected == null || !context.mounted) return;

    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Go to lesson?'),
        content: Text(
          'Open "${selected.lessonTitle}" to learn the missing sign first?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (go != true || !context.mounted) return;

    final lesson = await db.getLesson(selected.categoryId, selected.lessonId);
    if (lesson == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SignLearningPage(lesson: lesson, categoryId: selected.categoryId),
      ),
    );
  }
}
