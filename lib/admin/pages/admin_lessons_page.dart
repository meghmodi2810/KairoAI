import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';
import '../../services/admin_database_service.dart';

/// Admin Lessons Management Page - CRUD operations for lessons and signs
class AdminLessonsPage extends StatefulWidget {
  const AdminLessonsPage({super.key});

  @override
  State<AdminLessonsPage> createState() => _AdminLessonsPageState();
}

class _AdminLessonsPageState extends State<AdminLessonsPage>
    with SingleTickerProviderStateMixin {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();
  late TabController _tabController;
  String? _selectedCategoryId;
  String? _selectedLessonId;
  String _searchQuery = '';

  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
  static const Color cardBg = Color(0xFF262F4D);
  static const Color inputBg = Color(0xFF252A5E);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentBlue = Color(0xFF5CB6F9);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE57373);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkBlue,
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: cardBg,
            child: TabBar(
              controller: _tabController,
              indicatorColor: accentYellow,
              indicatorWeight: 3,
              labelColor: accentYellow,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Lessons'),
                Tab(text: 'Signs'),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsTab(),
                _buildSignsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LESSONS TAB ====================
  Widget _buildLessonsTab() {
    return Column(
      children: [
        _buildLessonsToolbar(),
        Expanded(
          child: Row(
            children: [
              // Categories Sidebar
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(
                    right: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: _buildCategoriesList(),
              ),
              // Lessons List
              Expanded(child: _buildLessonsList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search lessons...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            'Add Category',
            Icons.create_new_folder_outlined,
            accentPurple,
            () => _showAddCategoryDialog(),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            'Add Lesson',
            Icons.add_circle_outline,
            accentGreen,
            () => _showAddLessonDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Categories',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildCategoryItem(null, 'All Lessons', Icons.list_alt_rounded),
        Expanded(
          child: StreamBuilder<List<CategoryModel>>(
            stream: _adminDbService.categoriesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: accentYellow),
                );
              }

              final categories = snapshot.data!;

              if (categories.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No categories yet',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryItem(
                    category.id,
                    category.name,
                    _getCategoryIcon(category.name),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String? id, String name, IconData icon) {
    final isSelected = _selectedCategoryId == id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCategoryId = id),
          onLongPress: id != null ? () => _showCategoryOptions(id, name) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? accentYellow.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? accentYellow : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? accentYellow : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('alphabet')) return Icons.abc;
    if (lower.contains('number')) return Icons.numbers;
    if (lower.contains('greeting')) return Icons.waving_hand;
    if (lower.contains('emotion')) return Icons.emoji_emotions;
    if (lower.contains('animal')) return Icons.pets;
    if (lower.contains('food')) return Icons.fastfood;
    if (lower.contains('color')) return Icons.palette;
    if (lower.contains('family')) return Icons.family_restroom;
    return Icons.folder_outlined;
  }

  Widget _buildLessonsList() {
    return FutureBuilder<List<AdminLessonModel>>(
      future: _adminDbService.getAllLessons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: accentYellow),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  color: Colors.white.withOpacity(0.3),
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'No lessons yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showAddLessonDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Lesson'),
                  style: TextButton.styleFrom(foregroundColor: accentGreen),
                ),
              ],
            ),
          );
        }

        var lessons = snapshot.data!;

        // Filter by category
        if (_selectedCategoryId != null) {
          lessons = lessons.where((l) => l.categoryId == _selectedCategoryId).toList();
        }

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          lessons = lessons
              .where((l) =>
                  l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  l.description.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (lessons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  color: Colors.white.withOpacity(0.3),
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No lessons found'
                      : 'No lessons in this category',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: accentYellow,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: lessons.length,
            itemBuilder: (context, index) => _buildLessonCard(lessons[index]),
          ),
        );
      },
    );
  }

  Widget _buildLessonCard(AdminLessonModel lesson) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditLessonDialog(lesson),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getLessonTypeIcon(lesson.type),
                        color: accentBlue,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: lesson.isPublished
                            ? accentGreen.withOpacity(0.2)
                            : accentOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lesson.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          color: lesson.isPublished ? accentGreen : accentOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5), size: 20),
                      color: cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            lesson.isPublished ? 'Unpublish' : 'Publish',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: accentRed))),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') _showEditLessonDialog(lesson);
                        if (value == 'toggle') _toggleLessonPublished(lesson);
                        if (value == 'delete') _confirmDeleteLesson(lesson);
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  lesson.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLessonStat(Icons.gesture, '${lesson.totalSigns} signs'),
                    const SizedBox(width: 12),
                    _buildLessonStat(Icons.timer_outlined, '${lesson.estimatedMinutes} min'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  IconData _getLessonTypeIcon(LessonType type) {
    switch (type) {
      case LessonType.alphabet:
        return Icons.abc;
      case LessonType.numeric:
        return Icons.numbers;
      case LessonType.both:
        return Icons.text_fields;
    }
  }

  // ==================== SIGNS TAB ====================
  Widget _buildSignsTab() {
    return Column(
      children: [
        _buildSignsToolbar(),
        Expanded(child: _buildSignsContent()),
      ],
    );
  }

  Widget _buildSignsToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search signs...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (_selectedCategoryId != null && _selectedLessonId != null)
            _buildToolbarButton(
              'Add Sign',
              Icons.add_circle_outline,
              accentGreen,
              () => _showAddSignDialog(),
            ),
        ],
      ),
    );
  }

  Widget _buildSignsContent() {
    return Row(
      children: [
        // Category/Lesson selector sidebar
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: _buildLessonSelector(),
        ),
        // Signs grid
        Expanded(child: _buildSignsGrid()),
      ],
    );
  }

  Widget _buildLessonSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select a lesson to view signs',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CategoryModel>>(
            stream: _adminDbService.categoriesStream(),
            builder: (context, catSnapshot) {
              if (!catSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: accentYellow));
              }

              final categories = catSnapshot.data!;

              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, catIndex) {
                  final category = categories[catIndex];
                  return ExpansionTile(
                    title: Text(
                      category.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    leading: Icon(_getCategoryIcon(category.name), color: accentYellow, size: 20),
                    iconColor: Colors.white54,
                    collapsedIconColor: Colors.white54,
                    children: [
                      StreamBuilder<List<AdminLessonModel>>(
                        stream: _adminDbService.lessonsStream(category.id),
                        builder: (context, lessonSnapshot) {
                          if (!lessonSnapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Loading...', style: TextStyle(color: Colors.white54)),
                            );
                          }

                          final lessons = lessonSnapshot.data!;
                          if (lessons.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No lessons',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                            );
                          }

                          return Column(
                            children: lessons.map((lesson) {
                              final isSelected = _selectedLessonId == lesson.id;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: accentBlue.withOpacity(0.1),
                                title: Text(
                                  lesson.title,
                                  style: TextStyle(
                                    color: isSelected ? accentBlue : Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  '${lesson.totalSigns} signs',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 11,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = category.id;
                                    _selectedLessonId = lesson.id;
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSignsGrid() {
    if (_selectedCategoryId == null || _selectedLessonId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a lesson to view its signs',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<AdminSignModel>>(
      stream: _adminDbService.signsStream(_selectedCategoryId!, _selectedLessonId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: accentYellow),
          );
        }

        var signs = snapshot.data!;

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          signs = signs
              .where((s) =>
                  s.character.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s.description.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (signs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.gesture,
                  color: Colors.white.withOpacity(0.3),
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'No signs found' : 'No signs yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showAddSignDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Sign'),
                  style: TextButton.styleFrom(foregroundColor: accentGreen),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: signs.length,
          itemBuilder: (context, index) => _buildSignCard(signs[index]),
        );
      },
    );
  }

  Widget _buildSignCard(AdminSignModel sign) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSignDialog(sign),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: sign.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              sign.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderIcon(sign.character),
                            ),
                          )
                        : _buildPlaceholderIcon(sign.character),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sign.character,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sign.word != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sign.word!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5), size: 16),
                      padding: EdgeInsets.zero,
                      color: cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: accentRed))),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') _showEditSignDialog(sign);
                        if (value == 'delete') _confirmDeleteSign(sign);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(String character) {
    return Center(
      child: Text(
        character,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Category', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, 'Category Name', Icons.folder_outlined),
            const SizedBox(height: 16),
            _buildTextField(descController, 'Description (optional)', Icons.description_outlined, maxLines: 2),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                final category = CategoryModel(
                  id: '',
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  iconEmoji: '📚',
                  color: '#4A90D9',
                  order: 0,
                  totalLessons: 0,
                  totalSigns: 0,
                );
                await _adminDbService.createCategory(category);
                if (mounted) Navigator.pop(context);
                _showSnackBar('Category created successfully', accentGreen);
                setState(() {});
              } catch (e) {
                _showSnackBar('Error creating category: $e', accentRed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCategoryOptions(String categoryId, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete, color: accentRed),
              title: const Text('Delete Category', style: TextStyle(color: accentRed)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteCategory(categoryId, name);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(String categoryId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$name"?\nThis will also delete all lessons in this category.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminDbService.deleteCategory(categoryId);
                if (mounted) {
                  Navigator.pop(context);
                  if (_selectedCategoryId == categoryId) {
                    setState(() => _selectedCategoryId = null);
                  }
                }
                _showSnackBar('Category deleted', accentGreen);
              } catch (e) {
                _showSnackBar('Error: $e', accentRed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog() {
    _showLessonDialog(null);
  }

  void _showEditLessonDialog(AdminLessonModel lesson) {
    _showLessonDialog(lesson);
  }

  void _showLessonDialog(AdminLessonModel? lesson) {
    final isEdit = lesson != null;
    final titleController = TextEditingController(text: lesson?.title ?? '');
    final subtitleController = TextEditingController(text: lesson?.subtitle ?? '');
    final descController = TextEditingController(text: lesson?.description ?? '');
    final durationController = TextEditingController(text: (lesson?.estimatedMinutes ?? 5).toString());
    String? selectedCategoryId = lesson?.categoryId ?? _selectedCategoryId;
    LessonType selectedType = lesson?.type ?? LessonType.alphabet;
    bool isPublished = lesson?.isPublished ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Edit Lesson' : 'Add Lesson',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(titleController, 'Lesson Title', Icons.title),
                  const SizedBox(height: 16),
                  _buildTextField(subtitleController, 'Subtitle', Icons.subtitles),
                  const SizedBox(height: 16),
                  _buildTextField(descController, 'Description', Icons.description_outlined, maxLines: 3),
                  const SizedBox(height: 16),
                  // Category Dropdown
                  StreamBuilder<List<CategoryModel>>(
                    stream: _adminDbService.categoriesStream(),
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? <CategoryModel>[];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          value: selectedCategoryId,
                          hint: Text('Select Category', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          isExpanded: true,
                          dropdownColor: cardBg,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          items: categories.map((CategoryModel cat) {
                            return DropdownMenuItem<String>(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (value) => setDialogState(() => selectedCategoryId = value),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Lesson Type
                  Text('Lesson Type', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: LessonType.values.map((type) {
                      final isSelected = selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedType = type),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? accentBlue.withOpacity(0.2) : inputBg,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected ? Border.all(color: accentBlue) : null,
                            ),
                            child: Text(
                              type.displayName.split(' ')[0],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? accentBlue : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(durationController, 'Duration (minutes)', Icons.timer_outlined),
                  const SizedBox(height: 16),
                  // Published Toggle
                  Row(
                    children: [
                      Text('Published', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      const Spacer(),
                      Switch(
                        value: isPublished,
                        onChanged: (value) => setDialogState(() => isPublished = value),
                        activeColor: accentGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || selectedCategoryId == null) {
                  _showSnackBar('Please fill all required fields', accentOrange);
                  return;
                }
                try {
                  final lessonData = AdminLessonModel(
                    id: lesson?.id ?? '',
                    title: titleController.text.trim(),
                    subtitle: subtitleController.text.trim(),
                    description: descController.text.trim(),
                    categoryId: selectedCategoryId!,
                    type: selectedType,
                    signs: lesson?.signs ?? [],
                    testTypes: lesson?.testTypes ?? [],
                    order: lesson?.order ?? 0,
                    totalSigns: lesson?.totalSigns ?? 0,
                    estimatedMinutes: int.tryParse(durationController.text) ?? 5,
                    difficulty: lesson?.difficulty ?? 'beginner',
                    gemsReward: lesson?.gemsReward ?? 5,
                    coinsReward: lesson?.coinsReward ?? 50,
                    xpReward: lesson?.xpReward ?? 25,
                    isLocked: lesson?.isLocked ?? false,
                    requiredLessonId: lesson?.requiredLessonId,
                    focusPoints: lesson?.focusPoints ?? [],
                    thumbnailUrl: lesson?.thumbnailUrl,
                    createdAt: lesson?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                    createdBy: lesson?.createdBy,
                    isPublished: isPublished,
                  );

                  if (isEdit) {
                    await _adminDbService.updateLesson(lessonData);
                    _showSnackBar('Lesson updated', accentGreen);
                  } else {
                    await _adminDbService.createLesson(lessonData);
                    _showSnackBar('Lesson created', accentGreen);
                  }
                  if (mounted) Navigator.pop(context);
                  setState(() {});
                } catch (e) {
                  _showSnackBar('Error: $e', accentRed);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isEdit ? accentBlue : accentGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLessonPublished(AdminLessonModel lesson) async {
    try {
      final updated = lesson.copyWith(
        isPublished: !lesson.isPublished,
        updatedAt: DateTime.now(),
      );
      await _adminDbService.updateLesson(updated);
      _showSnackBar(
        lesson.isPublished ? 'Lesson unpublished' : 'Lesson published',
        accentGreen,
      );
      setState(() {});
    } catch (e) {
      _showSnackBar('Error: $e', accentRed);
    }
  }

  void _confirmDeleteLesson(AdminLessonModel lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Lesson', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${lesson.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminDbService.deleteLesson(lesson.categoryId, lesson.id);
                if (mounted) Navigator.pop(context);
                _showSnackBar('Lesson deleted', accentGreen);
                setState(() {});
              } catch (e) {
                _showSnackBar('Error: $e', accentRed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddSignDialog() {
    _showSignDialog(null);
  }

  void _showEditSignDialog(AdminSignModel sign) {
    _showSignDialog(sign);
  }

  void _showSignDialog(AdminSignModel? sign) {
    if (_selectedCategoryId == null || _selectedLessonId == null) {
      _showSnackBar('Please select a lesson first', accentOrange);
      return;
    }

    final isEdit = sign != null;
    final charController = TextEditingController(text: sign?.character ?? '');
    final wordController = TextEditingController(text: sign?.word ?? '');
    final descController = TextEditingController(text: sign?.description ?? '');
    final imageUrlController = TextEditingController(text: sign?.imageUrl ?? '');
    final videoUrlController = TextEditingController(text: sign?.videoUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Edit Sign' : 'Add Sign',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(charController, 'Character (e.g., A, B, 1)', Icons.abc),
                const SizedBox(height: 16),
                _buildTextField(wordController, 'Word (optional)', Icons.text_fields),
                const SizedBox(height: 16),
                _buildTextField(descController, 'Description', Icons.description_outlined, maxLines: 2),
                const SizedBox(height: 16),
                _buildTextField(imageUrlController, 'Image URL (optional)', Icons.image_outlined),
                const SizedBox(height: 16),
                _buildTextField(videoUrlController, 'Video URL (optional)', Icons.video_library_outlined),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (charController.text.trim().isEmpty) {
                _showSnackBar('Please enter a character', accentOrange);
                return;
              }
              try {
                final signData = AdminSignModel(
                  id: sign?.id ?? '',
                  lessonId: _selectedLessonId!,
                  character: charController.text.trim(),
                  word: wordController.text.trim().isNotEmpty ? wordController.text.trim() : null,
                  description: descController.text.trim(),
                  imageUrl: imageUrlController.text.trim().isNotEmpty ? imageUrlController.text.trim() : null,
                  videoUrl: videoUrlController.text.trim().isNotEmpty ? videoUrlController.text.trim() : null,
                  order: sign?.order ?? 0,
                  instructions: sign?.instructions ?? [],
                  difficulty: sign?.difficulty ?? 'easy',
                  createdAt: sign?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (isEdit) {
                  await _adminDbService.updateSign(_selectedCategoryId!, _selectedLessonId!, signData);
                  _showSnackBar('Sign updated', accentGreen);
                } else {
                  await _adminDbService.createSign(_selectedCategoryId!, _selectedLessonId!, signData);
                  _showSnackBar('Sign created', accentGreen);
                }
                if (mounted) Navigator.pop(context);
              } catch (e) {
                _showSnackBar('Error: $e', accentRed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isEdit ? accentBlue : accentGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSign(AdminSignModel sign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Sign', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${sign.character}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminDbService.deleteSign(_selectedCategoryId!, _selectedLessonId!, sign.id);
                if (mounted) Navigator.pop(context);
                _showSnackBar('Sign deleted', accentGreen);
              } catch (e) {
                _showSnackBar('Error: $e', accentRed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
