import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import 'login_page.dart';
import 'lesson_detail_page.dart';
import 'category_page.dart';

class NewHomePage extends StatefulWidget {
  const NewHomePage({super.key});

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  List<CategoryModel> _categories = [];
  DailyInsight? _dailyInsight;
  LessonModel? _nextLesson;
  String? _nextLessonCategoryId;
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
      // Ensure user document exists
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _databaseService.createUserDocument(currentUser);
      }

      // Load user data
      final user = await _databaseService.getCurrentUser();
      
      // Load categories
      final categories = await _databaseService.getCategories();
      
      // Load daily insight
      final insight = await _databaseService.getTodayInsight();
      
      // Find next lesson to continue
      LessonModel? nextLesson;
      String? nextCategoryId;
      
      if (categories.isNotEmpty) {
        // Get first unlocked category's first lesson
        final firstCategory = categories.first;
        final lessons = await _databaseService.getLessons(firstCategory.id);
        if (lessons.isNotEmpty) {
          nextLesson = lessons.first;
          nextCategoryId = firstCategory.id;
        }
      }

      if (mounted) {
        setState(() {
          _user = user;
          _categories = categories;
          _dailyInsight = insight;
          _nextLesson = nextLesson;
          _nextLessonCategoryId = nextCategoryId;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    }
  }

  void _seedData() async {
    setState(() => _isLoading = true);
    await _databaseService.seedInitialData();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentYellow),
            )
          : SafeArea(
              child: RefreshIndicator(
                color: accentYellow,
                backgroundColor: cardBg,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 24),
                        _buildDayInsightCard(),
                        const SizedBox(height: 28),
                        _buildCategoriesSection(),
                        const SizedBox(height: 28),
                        _buildDailyLessonCard(),
                        const SizedBox(height: 20),
                        if (_categories.isEmpty) _buildSeedDataButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // User greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                _user?.displayName ?? 'Learner',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Gems and Coins
        _buildStatChip('💎', _user?.gems ?? 0, const Color(0xFF6C5CE7)),
        const SizedBox(width: 8),
        _buildStatChip('🪙', _user?.coins ?? 0, const Color(0xFFFFAA00)),
      ],
    );
  }

  Widget _buildStatChip(String emoji, int value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            _formatNumber(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildDayInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardBg,
            cardBg.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Robot mascot
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: accentYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Day Insight',
                      style: TextStyle(
                        color: accentYellow,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: accentYellow,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _dailyInsight?.message ?? 'Learn something new today! Practice makes perfect.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all categories
              },
              child: const Text(
                'See All',
                style: TextStyle(color: accentYellow, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _categories.isEmpty
            ? _buildEmptyCategoriesState()
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(_categories[index]);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyCategoriesState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, color: Colors.white.withOpacity(0.4), size: 32),
            const SizedBox(height: 8),
            Text(
              'No categories yet',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap menu → Load Sample Data',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final Color categoryColor = _parseColor(category.color);
    
    return GestureDetector(
      onTap: () {
        if (!category.isLocked) {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                  CategoryPage(category: category),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              categoryColor.withOpacity(0.3),
              categoryColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: categoryColor.withOpacity(0.4)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.iconEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.totalSigns} signs',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (category.isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock, color: Colors.white54, size: 28),
                  ),
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

  Widget _buildDailyLessonCard() {
    if (_nextLesson == null) {
      return _buildNoLessonCard();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2D3368),
            Color(0xFF252A5E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: accentYellow, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_user?.streakDays ?? 0} Day Streak',
                      style: const TextStyle(
                        color: accentYellow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Unit ${_nextLesson!.unitNumber}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Lesson',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _nextLesson!.title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white.withOpacity(0.5),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_nextLesson!.estimatedMinutes} min',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.front_hand,
                          color: accentYellow,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_nextLesson!.totalSigns} signs',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Hand gesture illustration
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D4478),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🤟', style: TextStyle(fontSize: 40)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nextLesson != null && _nextLessonCategoryId != null) {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          LessonDetailPage(
                        lesson: _nextLesson!,
                        categoryId: _nextLessonCategoryId!,
                      ),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentYellow,
                foregroundColor: darkBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLessonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('📚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Ready to Learn?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Load sample data to start learning Indian Sign Language!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeedDataButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _seedData,
        icon: const Icon(Icons.cloud_download),
        label: const Text('Load Sample Data'),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: darkBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
