import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'sign_learning_page.dart';

/// Displays the lessons within a category
class CategoryLessonsPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryLessonsPage({super.key, required this.category});

  @override
  State<CategoryLessonsPage> createState() => _CategoryLessonsPageState();
}

class _CategoryLessonsPageState extends State<CategoryLessonsPage> {
  final DatabaseService _db = DatabaseService();
  List<LessonModel> _lessons = [];
  Map<String, LessonProgress> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await _db.getLessons(widget.category.id);
      final progressMap = <String, LessonProgress>{};
      for (final lesson in lessons) {
        final progress = await _db.getLessonProgress(lesson.id);
        if (progress != null) {
          progressMap[lesson.id] = progress;
        }
      }
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _progressMap = progressMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading lessons: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _categoryColor {
    try {
      return Color(int.parse(widget.category.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryIndigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _categoryColor,
                      _categoryColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.category.iconEmoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.category.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.category.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Progress bar
          SliverToBoxAdapter(
            child: _buildProgress(),
          ),
          // Lessons
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo)),
                )
              : _lessons.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty(cs))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildLessonCard(index, cs),
                          childCount: _lessons.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final cs = Theme.of(context).colorScheme;
    int completed = _progressMap.values.where((p) => p.status == 'completed').length;
    double pct = _lessons.isEmpty ? 0 : completed / _lessons.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
                Text(
                  '$completed / ${_lessons.length} completed',
                  style: const TextStyle(color: AppTheme.accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: cs.onSurface.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(_categoryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, color: cs.onSurface.withOpacity(0.35), size: 56),
          const SizedBox(height: 16),
          Text('No lessons yet', style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 18)),
          const SizedBox(height: 8),
          Text('Lessons will appear here once the admin adds them.',
              style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLessonCard(int index, ColorScheme cs) {
    final lesson = _lessons[index];
    final progress = _progressMap[lesson.id];
    final isCompleted = progress?.status == 'completed';
    final isInProgress = progress?.status == 'in_progress';

    // Determine lock status
    bool isLocked = false;
    if (lesson.requiredLessonId != null && index > 0) {
      final req = _progressMap[lesson.requiredLessonId];
      isLocked = req?.status != 'completed';
    }

    Color statusColor = cs.onSurface.withOpacity(0.35);
    IconData statusIcon = Icons.circle_outlined;
    if (isCompleted) {
      statusColor = AppTheme.accentGreen;
      statusIcon = Icons.check_circle;
    } else if (isInProgress) {
      statusColor = AppTheme.accentAmber;
      statusIcon = Icons.play_circle_filled;
    } else if (isLocked) {
      statusIcon = Icons.lock;
    }

    String difficultyLabel = lesson.difficulty;
    Color difficultyColor;
    switch (lesson.difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        difficultyColor = AppTheme.accentGreen;
        difficultyLabel = 'Beginner';
        break;
      case 'medium':
      case 'intermediate':
        difficultyColor = AppTheme.accentAmber;
        difficultyLabel = 'Intermediate';
        break;
      case 'hard':
      case 'advanced':
        difficultyColor = AppTheme.errorRed;
        difficultyLabel = 'Advanced';
        break;
      default:
        difficultyColor = cs.onSurface.withOpacity(0.35);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: isLocked
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLocked ? cs.surface.withOpacity(0.5) : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.accentGreen.withOpacity(0.4)
                  : isInProgress
                      ? AppTheme.accentAmber.withOpacity(0.3)
                      : cs.onSurface.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              // Unit number circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted || isLocked || isInProgress
                      ? Icon(statusIcon, color: statusColor, size: 24)
                      : Text(
                          '${lesson.unitNumber}',
                          style: TextStyle(
                            color: _categoryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        color: isLocked ? cs.onSurface.withOpacity(0.35) : cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: difficultyColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            difficultyLabel,
                            style: TextStyle(color: difficultyColor, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, color: cs.onSurface.withOpacity(0.35), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              '${lesson.estimatedMinutes} min',
                              style: TextStyle(color: cs.onSurface.withOpacity(0.35), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Rewards
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond, color: AppTheme.gemPurple, size: 14),
                      const SizedBox(width: 3),
                      Text('+${lesson.gemsReward}',
                          style: const TextStyle(color: AppTheme.gemPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, color: AppTheme.accentAmber, size: 14),
                      const SizedBox(width: 3),
                      Text('+${lesson.xpReward}',
                          style: const TextStyle(color: AppTheme.accentAmber, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
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
