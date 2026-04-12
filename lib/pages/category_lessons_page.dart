import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'sign_learning_page.dart';

class CategoryLessonsPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryLessonsPage({super.key, required this.category});

  @override
  State<CategoryLessonsPage> createState() => _CategoryLessonsPageState();
}

class _CategoryLessonsPageState extends State<CategoryLessonsPage> {
  final DatabaseService _db = DatabaseService();

  List<LessonModel> _lessons = [];
  Map<String, LessonProgress> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await _db.getLessons(widget.category.id);
      final map = <String, LessonProgress>{};
      for (final lesson in lessons) {
        final p = await _db.getLessonProgress(lesson.id);
        if (p != null) map[lesson.id] = p;
      }
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _progress = map;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load category lessons: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _categoryColor() {
    try {
      return Color(int.parse(widget.category.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.cobaltBlue;
    }
  }

  Color _categoryTextColor(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? AppTheme.warmWhite : AppTheme.inkBlack;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor();
    final categoryTextColor = _categoryTextColor(categoryColor);
    final completed = _progress.values.where((p) => p.status == 'completed').length;
    final ratio = _lessons.isEmpty ? 0.0 : completed / _lessons.length;

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
                        color: categoryColor,
                        radius: 16,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            Text(widget.category.iconEmoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.category.name,
                                    style: TextStyle(
                                      color: categoryTextColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.category.description,
                                    style: TextStyle(
                                      color: categoryTextColor.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: NeoPanel(
                color: AppTheme.softPeach,
                radius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PATH PROGRESS',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '$completed / ${_lessons.length}',
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: AppTheme.warmWhite,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mintGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.cobaltBlue)),
            )
          else if (_lessons.isEmpty)
            SliverFillRemaining(
              child: NeoEmptyState(
                icon: Icons.school_outlined,
                title: 'No Lessons Yet',
                subtitle: 'This category does not have lessons yet.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
              sliver: SliverList.builder(
                itemCount: _lessons.length,
                itemBuilder: (context, index) => _lessonCard(_lessons[index], index, categoryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _lessonCard(LessonModel lesson, int index, Color color) {
    final progress = _progress[lesson.id];
    final completed = progress?.status == 'completed';
    final inProgress = progress?.status == 'in_progress';

    bool locked = false;
    if (lesson.requiredLessonId != null && index > 0) {
      final req = _progress[lesson.requiredLessonId];
      locked = req?.status != 'completed';
    }

    final difficulty = lesson.difficulty.toLowerCase();
    final difficultyColor = switch (difficulty) {
      'easy' || 'beginner' => AppTheme.mintGreen,
      'medium' || 'intermediate' => AppTheme.signalYellow,
      'hard' || 'advanced' => AppTheme.punchRed,
      _ => AppTheme.electricBlue,
    };

    IconData statusIcon = Icons.circle_outlined;
    Color statusColor = AppTheme.inkBlack;
    if (locked) {
      statusIcon = Icons.lock;
      statusColor = AppTheme.inkBlack.withValues(alpha: 0.6);
    } else if (completed) {
      statusIcon = Icons.check_circle;
      statusColor = AppTheme.mintGreen;
    } else if (inProgress) {
      statusIcon = Icons.play_circle_fill;
      statusColor = AppTheme.signalYellow;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: locked
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignLearningPage(
                      lesson: lesson,
                      categoryId: widget.category.id,
                    ),
                  ),
                ).then((_) => _loadLessons());
              },
        child: NeoPanel(
          color: locked ? AppTheme.paperCream : AppTheme.warmWhite,
          radius: 16,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: locked ? AppTheme.paperCream : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.inkBlack, width: 2),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        color: locked ? AppTheme.inkBlack.withValues(alpha: 0.6) : AppTheme.inkBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: difficultyColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.inkBlack, width: 2),
                          ),
                          child: Text(
                            lesson.difficulty.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${lesson.estimatedMinutes} min',
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${lesson.gemsReward} 💎',
                    style: const TextStyle(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${lesson.xpReward} XP',
                    style: const TextStyle(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
