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
  bool _isAudioPlaying = false;
  int _selectedCategoryIndex = 0;

  // Theme colors matching the design
  static const Color darkBlue = Color(0xFF1A1F38);
  static const Color cardBg = Color(0xFF252B4D);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color gemPurple = Color(0xFF8B7BF7);
  static const Color coinGold = Color(0xFFFFAA00);

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
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
        // Back button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              // Navigate back or show menu
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
        const Spacer(),
        // Gems
        _buildStatChip(
          icon: Icons.diamond_rounded,
          value: _user?.gems ?? 144,
          color: gemPurple,
        ),
        const SizedBox(width: 12),
        // Coins
        _buildStatChip(
          icon: Icons.monetization_on_rounded,
          value: _user?.coins ?? 2321,
          color: coinGold,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            _formatNumber(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return number.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return number.toString();
  }

  Widget _buildDayInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Robot mascot image
          Container(
            width: 100,
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Robot styled container
                Container(
                  width: 100,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF4ECDC4).withOpacity(0.2),
                        const Color(0xFF4ECDC4).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Robot head with goggles
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 55,
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A6A7A),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          // Goggles/Eyes
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD93D),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF8B6914),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD93D),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF8B6914),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Robot body
                      Container(
                        width: 45,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2A8A82),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2A8A82),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Day Insight content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Day Insight',
                  style: TextStyle(
                    color: accentYellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Listen every Day Insight\nabout your education',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                // Audio player
                _buildAudioPlayer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: () {
              setState(() {
                _isAudioPlaying = !_isAudioPlaying;
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: accentYellow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isAudioPlaying
                    ? Icons.pause_rounded
                    : Icons.graphic_eq_rounded,
                color: darkBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Audio waveform visualization
          Row(
            children: List.generate(
              8,
              (index) {
                final heights = [12.0, 20.0, 8.0, 24.0, 14.0, 22.0, 10.0, 18.0];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 3,
                  height: heights[index],
                  decoration: BoxDecoration(
                    color: accentYellow.withOpacity(_isAudioPlaying ? 1.0 : 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
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
              'Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to all categories
              },
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _categories.isEmpty
            ? _buildDefaultCategories()
            : SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(_categories[index], index);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildDefaultCategories() {
    // Default categories matching the design
    final defaultCategories = [
      {'name': 'Greetings', 'icon': Icons.waving_hand_rounded, 'color': accentYellow},
      {'name': 'Numbers', 'icon': Icons.groups_rounded, 'color': const Color(0xFF6C9EFF)},
      {'name': 'History', 'icon': Icons.access_time_rounded, 'color': const Color(0xFF6C9EFF)},
      {'name': 'Animals', 'icon': Icons.pets_rounded, 'color': const Color(0xFF4ECDC4)},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: defaultCategories.length,
        itemBuilder: (context, index) {
          final category = defaultCategories[index];
          return _buildDefaultCategoryCard(
            name: category['name'] as String,
            icon: category['icon'] as IconData,
            color: category['color'] as Color,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildDefaultCategoryCard({
    required String name,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    final bool isSelected = _selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentYellow : cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? darkBlue : color,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? darkBlue : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    final Color categoryColor = _parseColor(category.color);
    final bool isSelected = _selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
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
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentYellow : cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : categoryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      category.iconEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected ? darkBlue : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (category.isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock, color: Colors.white54, size: 24),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Lesson',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hand gesture image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A4070),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '👋',
                    style: TextStyle(fontSize: 52),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Lesson details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Unit ${_nextLesson?.unitNumber ?? 1}:',
                        style: TextStyle(
                          color: accentYellow.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _nextLesson?.title ?? 'Greetings',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Rewards row
                    Row(
                      children: [
                        _buildRewardChip(
                          icon: Icons.diamond_rounded,
                          value: '+5',
                          color: gemPurple,
                        ),
                        const SizedBox(width: 10),
                        _buildRewardChip(
                          icon: Icons.monetization_on_rounded,
                          value: '+50 Coins',
                          color: coinGold,
                        ),
                      ],
                    ),
                  ],
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
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
        borderRadius: BorderRadius.circular(24),
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
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
