import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'category_lessons_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _db = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  List<CategoryModel> _categories = [];
  LessonModel? _continueLesson;
  String? _continueCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _db.createUserDocument(currentUser);
      }
      final user = await _db.getCurrentUser();
      final categories = await _db.getCategories();

      LessonModel? nextLesson;
      String? nextCatId;
      if (categories.isNotEmpty) {
        for (final cat in categories) {
          if (cat.isLocked) continue;
          final lessons = await _db.getLessons(cat.id);
          for (final lesson in lessons) {
            final progress = await _db.getLessonProgress(lesson.id);
            if (progress == null || progress.status != 'completed') {
              nextLesson = lesson;
              nextCatId = cat.id;
              break;
            }
          }
          if (nextLesson != null) break;
        }
      }

      if (mounted) {
        setState(() {
          _user = user;
          _categories = categories;
          _continueLesson = nextLesson;
          _continueCategoryId = nextCatId;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SafeArea(
              child: RefreshIndicator(
                color: cs.primary,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreeting(cs),
                      const SizedBox(height: 24),
                      _buildStatsRow(cs),
                      const SizedBox(height: 28),
                      if (_continueLesson != null) ...[
                        _buildContinueLearning(cs),
                        const SizedBox(height: 28),
                      ],
                      _buildDailyGoal(cs),
                      const SizedBox(height: 28),
                      Text('Categories', style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      _buildCategoriesList(cs),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGreeting(ColorScheme cs) {
    final name = _user?.displayName ?? _auth.currentUser?.displayName ?? 'Learner';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting 👋', style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(color: cs.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: AppTheme.accentAmber, size: 18),
              const SizedBox(width: 4),
              Text('${_user?.xp ?? 0} XP', style: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ColorScheme cs) {
    return Row(
      children: [
        _buildStatCard(Icons.local_fire_department_rounded, '${_user?.streakDays ?? 0}', 'Day Streak', const Color(0xFFF97316), cs),
        const SizedBox(width: 12),
        _buildStatCard(Icons.diamond_rounded, '${_user?.gems ?? 0}', 'Gems', AppTheme.gemPurple, cs),
        const SizedBox(width: 12),
        _buildStatCard(Icons.monetization_on_rounded, '${_user?.coins ?? 0}', 'Coins', AppTheme.coinGold, cs),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearning(ColorScheme cs) {
    final lesson = _continueLesson!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Continue Learning', style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => CategoryLessonsPage(
                category: _categories.firstWhere((c) => c.id == _continueCategoryId, orElse: () => _categories.first),
              ),
            ));
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.sign_language, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Unit ${lesson.unitNumber} • ${lesson.estimatedMinutes} min', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoal(ColorScheme cs) {
    final goal = _user?.dailyGoalMinutes ?? 10;
    final practiceMinutes = _user?.totalPracticeMinutes ?? 0;
    final progress = (practiceMinutes / goal).clamp(0.0, 1.0);
    final completed = _user?.totalLessonsCompleted ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Goal', style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('$practiceMinutes / $goal min', style: const TextStyle(color: AppTheme.accentGreen, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: cs.onSurface.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.school, color: cs.onSurface.withOpacity(0.35), size: 16),
              const SizedBox(width: 6),
              Text('$completed lessons', style: TextStyle(color: cs.onSurface.withOpacity(0.55), fontSize: 13)),
              const SizedBox(width: 20),
              Icon(Icons.front_hand, color: cs.onSurface.withOpacity(0.35), size: 16),
              const SizedBox(width: 6),
              Text('${_user?.totalSignsLearned ?? 0} signs', style: TextStyle(color: cs.onSurface.withOpacity(0.55), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(ColorScheme cs) {
    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.category_outlined, color: cs.onSurface.withOpacity(0.25), size: 48),
              const SizedBox(height: 12),
              Text('No categories yet', style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 16)),
              const SizedBox(height: 4),
              Text('Ask your admin to add learning categories', style: TextStyle(color: cs.onSurface.withOpacity(0.35), fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final color = _parseColor(cat.color);
        return GestureDetector(
          onTap: cat.isLocked
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reach level ${cat.requiredLevel} to unlock ${cat.name}')),
                  )
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryLessonsPage(category: cat))),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cat.isLocked ? cs.onSurface.withOpacity(0.06) : color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: cat.isLocked ? cs.onSurface.withOpacity(0.06) : color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: cat.isLocked
                        ? Icon(Icons.lock, color: cs.onSurface.withOpacity(0.3), size: 20)
                        : Text(cat.iconEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name, style: TextStyle(color: cat.isLocked ? cs.onSurface.withOpacity(0.35) : cs.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(cat.description, style: TextStyle(color: cs.onSurface.withOpacity(0.45), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${cat.totalLessons}', style: TextStyle(color: cat.isLocked ? cs.onSurface.withOpacity(0.3) : color, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('lessons', style: TextStyle(color: cs.onSurface.withOpacity(0.35), fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.3), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryIndigo;
    }
  }
}
