import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import 'lesson_detail_page.dart';

class CategoryPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<LessonModel> _lessons = [];
  Map<String, LessonProgress> _progressMap = {};
  bool _isLoading = true;

  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color cardBg = Color(0xFF252A5E);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final lessons = await _databaseService.getLessons(widget.category.id);
      
      // Load progress for each lesson
      final progressMap = <String, LessonProgress>{};
      for (final lesson in lessons) {
        final progress = await _databaseService.getLessonProgress(lesson.id);
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
      print('Error loading lessons: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _parseColor(widget.category.color);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentYellow),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header
                  _buildCategoryHeader(categoryColor),
                  const SizedBox(height: 24),
                  
                  // Progress Section
                  _buildProgressSection(categoryColor),
                  const SizedBox(height: 24),
                  
                  // Lessons List
                  const Text(
                    'Lessons',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _lessons.isEmpty
                      ? _buildEmptyState()
                      : _buildLessonsList(categoryColor),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryHeader(Color categoryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withOpacity(0.3),
            categoryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: categoryColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                widget.category.iconEmoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.category.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.book, '${widget.category.totalLessons} lessons'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.front_hand, '${widget.category.totalSigns} signs'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(Color categoryColor) {
    int completedLessons = 0;
    for (final progress in _progressMap.values) {
      if (progress.status == 'completed') {
        completedLessons++;
      }
    }
    
    final progressPercent = _lessons.isEmpty 
        ? 0.0 
        : (completedLessons / _lessons.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$completedLessons/${_lessons.length} Completed',
                style: const TextStyle(
                  color: accentYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList(Color categoryColor) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lessons.length,
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        final progress = _progressMap[lesson.id];
        final isCompleted = progress?.status == 'completed';
        final isInProgress = progress?.status == 'in_progress';
        
        // Check if lesson is unlocked
        bool isLocked = false;
        if (lesson.requiredLessonId != null && index > 0) {
          final requiredProgress = _progressMap[lesson.requiredLessonId];
          isLocked = requiredProgress?.status != 'completed';
        }

        return _buildLessonCard(
          lesson,
          categoryColor,
          isCompleted: isCompleted,
          isInProgress: isInProgress,
          isLocked: isLocked,
        );
      },
    );
  }

  Widget _buildLessonCard(
    LessonModel lesson,
    Color categoryColor, {
    bool isCompleted = false,
    bool isInProgress = false,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LessonDetailPage(
                    lesson: lesson,
                    categoryId: widget.category.id,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked ? cardBg.withOpacity(0.5) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? Colors.green.withOpacity(0.5)
                : isInProgress
                    ? categoryColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
            width: isCompleted || isInProgress ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Unit number badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.2)
                    : categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.green, size: 24)
                    : Text(
                        '${lesson.unitNumber}',
                        style: TextStyle(
                          color: isLocked ? Colors.white38 : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Lesson info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.subtitle,
                    style: TextStyle(
                      color: isLocked 
                          ? Colors.white24 
                          : Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLessonStat(
                        Icons.front_hand,
                        '${lesson.totalSigns} signs',
                        isLocked,
                      ),
                      const SizedBox(width: 16),
                      _buildLessonStat(
                        Icons.access_time,
                        '${lesson.estimatedMinutes} min',
                        isLocked,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow or lock
            Icon(
              isLocked ? Icons.lock : Icons.arrow_forward_ios,
              color: isLocked 
                  ? Colors.white24 
                  : Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonStat(IconData icon, String text, bool isLocked) {
    return Row(
      children: [
        Icon(
          icon,
          color: isLocked ? Colors.white24 : Colors.white38,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isLocked ? Colors.white24 : Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No lessons available yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4A90D9);
    }
  }
}
