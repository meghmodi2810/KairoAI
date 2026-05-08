import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'category_lessons_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _db = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache variables
  static UserModel? _cachedUser;
  static List<CategoryModel>? _cachedCategories;
  static LessonModel? _cachedContinueLesson;
  static String? _cachedContinueCategoryId;
  static DateTime? _lastCacheTime;
  
  static const Duration _cacheValidity = Duration(minutes: 5);
  
  bool get _isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheValidity;
  }

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
    // Use cached data immediately if valid
    if (_isCacheValid && _cachedUser != null) {
      setState(() {
        _user = _cachedUser;
        _categories = _cachedCategories ?? [];
        _continueLesson = _cachedContinueLesson;
        _continueCategoryId = _cachedContinueCategoryId;
        _isLoading = false;
      });
      
      // Refresh in background
      _refreshData();
      return;
    }
    
    // Load fresh data
    await _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _db.createUserDocument(currentUser);
      }

      // Parallel data fetching
      final results = await Future.wait([
        _db.getCurrentUser(),
        _db.getCategories(),
      ]);

      final user = results[0] as UserModel?;
      final categories = results[1] as List<CategoryModel>;

      // Find continue lesson (optimized)
      LessonModel? nextLesson;
      String? nextCategoryId;

      for (final category in categories) {
        if (category.isLocked) continue;
        final lessons = await _db.getLessons(category.id);
        for (final lesson in lessons) {
          final progress = await _db.getLessonProgress(lesson.id);
          if (progress == null || progress.status != 'completed') {
            nextLesson = lesson;
            nextCategoryId = category.id;
            break;
          }
        }
        if (nextLesson != null) break;
      }

      // Update cache
      _cachedUser = user;
      _cachedCategories = categories;
      _cachedContinueLesson = nextLesson;
      _cachedContinueCategoryId = nextCategoryId;
      _lastCacheTime = DateTime.now();

      if (!mounted) return;
      setState(() {
        _user = user;
        _categories = categories;
        _continueLesson = nextLesson;
        _continueCategoryId = nextCategoryId;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.cobaltBlue,
          onRefresh: _refreshData,
          child: _isLoading && _user == null
              ? _buildSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 14),
                      _statsRow(),
                      if (_continueLesson != null) ...[
                        const SizedBox(height: 18),
                        _continueCard(),
                      ],
                      const SizedBox(height: 18),
                      _dailyGoalSection(),
                      const SizedBox(height: 20),
                      const Text(
                        'FEATURED CATEGORIES',
                        style: TextStyle(
                          color: AppTheme.inkBlack,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _categoriesList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBox(height: 60, width: double.infinity),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildSkeletonBox(height: 100)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonBox(height: 100)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonBox(height: 100)),
            ],
          ),
          const SizedBox(height: 18),
          _buildSkeletonBox(height: 120, width: double.infinity),
          const SizedBox(height: 18),
          _buildSkeletonBox(height: 150, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.warmWhite.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.inkBlack.withValues(alpha: 0.1), width: 2),
      ),
    );
  }

  Widget _header() {
    final name =
        _user?.displayName ?? _auth.currentUser?.displayName ?? 'Learner';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(
                  color: AppTheme.inkBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.inkBlack,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        NeoSticker(
          label: '${_user?.xp ?? 0} XP',
          color: AppTheme.signalYellow,
          icon: Icons.bolt,
        ),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statCard(
          icon: Icons.local_fire_department,
          value: '${_user?.streakDays ?? 0}',
          label: 'STREAK',
          color: AppTheme.punchRed,
        ),
        const SizedBox(width: 8),
        _statCard(
          icon: Icons.diamond,
          value: '${_user?.gems ?? 0}',
          label: 'GEMS',
          color: AppTheme.gemPurple,
        ),
        const SizedBox(width: 8),
        _statCard(
          icon: Icons.monetization_on,
          value: '${_user?.coins ?? 0}',
          label: 'COINS',
          color: AppTheme.signalYellow,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: NeoPanel(
        color: AppTheme.warmWhite,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.inkBlack,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continueCard() {
    final lesson = _continueLesson!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTINUE LEARNING',
          style: TextStyle(
            color: AppTheme.inkBlack,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryLessonsPage(
                  category: _categories.firstWhere(
                    (c) => c.id == _continueCategoryId,
                    orElse: () => _categories.first,
                  ),
                ),
              ),
            );
          },
          child: NeoPanel(
            color: AppTheme.cobaltBlue,
            radius: 18,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.signalYellow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.inkBlack, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.sign_language,
                    color: AppTheme.inkBlack,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          color: AppTheme.warmWhite,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unit ${lesson.unitNumber} • ${lesson.estimatedMinutes} min',
                        style: const TextStyle(
                          color: AppTheme.warmWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.mintGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.inkBlack, width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppTheme.inkBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dailyGoalSection() {
    return StreamBuilder<UserModel?>(
      stream: _db.userStream(),
      initialData: _user,
      builder: (context, snapshot) {
        return _dailyGoalCard(snapshot.data ?? _user);
      },
    );
  }

  Widget _dailyGoalCard(UserModel? user) {
    final goal = user?.dailyGoalMinutes ?? 10;
    final practiceMinutes = _todayLessonMinutes(user);
    final progress = goal <= 0 ? 0.0 : (practiceMinutes / goal).clamp(0.0, 1.0);
    final remaining = (goal - practiceMinutes).clamp(0, goal);

    return NeoPanel(
      color: AppTheme.softPeach,
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAILY GOAL',
                style: TextStyle(
                  color: AppTheme.inkBlack,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$practiceMinutes / $goal min',
                style: const TextStyle(
                  color: AppTheme.inkBlack,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppTheme.warmWhite,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.mintGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remaining == 0
                ? 'Goal complete. Great consistency today.'
                : '$remaining min left in today\'s lesson goal.',
            style: const TextStyle(
              color: AppTheme.inkBlack,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  int _todayLessonMinutes(UserModel? user) {
    if (user == null || user.todayLessonPracticeDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = user.todayLessonPracticeDate!;
    final tracked = DateTime(date.year, date.month, date.day);

    if (tracked != today) return 0;
    return user.todayLessonPracticeMinutes;
  }

  Widget _categoriesList() {
    if (_categories.isEmpty) {
      return NeoEmptyState(
        icon: Icons.category_outlined,
        title: 'No Categories Yet',
        subtitle: 'Ask your admin to publish learning packs.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final color = _parseColor(category.color);

        return GestureDetector(
          onTap: category.isLocked
              ? () {
                  AudioService().playClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Reach level ${category.requiredLevel} to unlock ${category.name}.',
                    ),
                  ),
                );
                }
              : () {
                  AudioService().playClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryLessonsPage(category: category),
                    ),
                  );
                },
          child: NeoPanel(
            radius: 16,
            color: AppTheme.warmWhite,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: category.isLocked
                        ? AppTheme.paperCream
                        : color.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.inkBlack, width: 2),
                  ),
                  child: Center(
                    child: category.isLocked
                        ? const Icon(Icons.lock, color: AppTheme.inkBlack)
                        : (category.iconUrl != null && category.iconUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.network(
                                  category.iconUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    category.iconEmoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              )
                            : Text(
                                category.iconEmoji,
                                style: const TextStyle(fontSize: 24),
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
                          color: category.isLocked
                              ? AppTheme.inkBlack.withValues(alpha: 0.6)
                              : AppTheme.inkBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category.description,
                        style: const TextStyle(
                          color: AppTheme.inkBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .doc(category.id)
                      .collection('lessons')
                      .snapshots(),
                  builder: (context, lessonsSnapshot) {
                    final totalLessons =
                        lessonsSnapshot.data?.docs.length ??
                        category.totalLessons;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$totalLessons',
                          style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'LESSONS',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String value) {
    try {
      return Color(int.parse(value.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.cobaltBlue;
    }
  }
}
