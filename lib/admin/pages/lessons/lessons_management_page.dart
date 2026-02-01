import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../widgets/admin_widgets.dart';
import '../../../models/app_models.dart';

class LessonsManagementPage extends StatefulWidget {
  final AdminModel admin;

  const LessonsManagementPage({super.key, required this.admin});

  @override
  State<LessonsManagementPage> createState() => _LessonsManagementPageState();
}

class _LessonsManagementPageState extends State<LessonsManagementPage> with SingleTickerProviderStateMixin {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    _dbService.categoriesStream().listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(),
                _buildAllLessonsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AdminTheme.accentYellow,
        foregroundColor: AdminTheme.primaryDark,
        mini: true,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Lessons',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage categories & lessons',
                      style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadCategories,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: const TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20, color: AdminTheme.textSecondary),
              filled: true,
              fillColor: AdminTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: AdminTheme.accentYellow,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: AdminTheme.primaryDark,
        unselectedLabelColor: AdminTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Categories'),
          Tab(text: 'All Lessons'),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow)),
      );
    }

    if (_categories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        title: 'No Categories Yet',
        subtitle: 'Create your first category',
        onAction: _showCreateCategoryDialog,
      );
    }

    final filteredCategories = _categories.where((c) {
      final query = _searchController.text.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.description.toLowerCase().contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) => _buildCategoryCard(filteredCategories[index]),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final color = _parseColor(category.color);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showCategoryDetails(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(category.iconEmoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.description,
                      style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMiniStat(Icons.book, '${category.totalLessons}', color),
                        const SizedBox(width: 10),
                        _buildMiniStat(Icons.sign_language, '${category.totalSigns}', color),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AdminTheme.textSecondary, size: 20),
                onSelected: (action) => _handleCategoryAction(action, category),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAllLessonsTab() {
    if (_categories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        title: 'No Categories',
        subtitle: 'Create a category first',
        onAction: _showCreateCategoryDialog,
      );
    }

    return Column(
      children: [
        // Category selector
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategoryId == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('${cat.iconEmoji} ${cat.name}'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                  backgroundColor: AdminTheme.cardBg,
                  selectedColor: AdminTheme.accentYellow,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AdminTheme.primaryDark : AdminTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: AdminTheme.primaryDark,
                ),
              );
            },
          ),
        ),
        // Lessons content
        Expanded(
          child: _selectedCategoryId == null
              ? _buildEmptyState(
                  icon: Icons.touch_app,
                  title: 'Select Category',
                  subtitle: 'Choose a category above',
                )
              : _buildLessonsList(),
        ),
      ],
    );
  }

  Widget _buildLessonsList() {
    final category = _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.iconEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                ),
              ),
              TextButton.icon(
                onPressed: _showCreateLessonDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminTheme.info.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline, color: AdminTheme.info, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Lessons Info',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'This category has ${category.totalLessons} lessons with ${category.totalSigns} signs. '
                  'Lessons are managed through the database.',
                  style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AdminTheme.textSecondary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.accentYellow,
                foregroundColor: AdminTheme.primaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateDialog() {
    if (_tabController.index == 0) {
      _showCreateCategoryDialog();
    } else {
      _showCreateLessonDialog();
    }
  }

  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '📚';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Category', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AdminTheme.textSecondary)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AdminTheme.textSecondary)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedEmoji,
                dropdownColor: AdminTheme.cardBg,
                decoration: const InputDecoration(labelText: 'Icon'),
                items: ['📚', '👋', '🔢', '🔤', '👨‍👩‍👧‍👦', '🌈', '🐾', '⭐']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => selectedEmoji = v ?? selectedEmoji,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final category = CategoryModel(
                  id: nameController.text.toLowerCase().replaceAll(' ', '_'),
                  name: nameController.text,
                  description: descController.text,
                  iconEmoji: selectedEmoji,
                  color: '#4A90D9',
                  order: _categories.length + 1,
                  totalLessons: 0,
                  totalSigns: 0,
                );
                await _dbService.createCategory(category);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category created!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accentYellow, foregroundColor: AdminTheme.primaryDark),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateLessonDialog() {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Lesson', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Lessons are managed through the database. Contact development team for changes.',
          style: TextStyle(color: AdminTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accentYellow, foregroundColor: AdminTheme.primaryDark),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.cardBg,
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
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(category.iconEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(category.description, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDetailChip('Lessons', '${category.totalLessons}', AdminTheme.info),
                const SizedBox(width: 8),
                _buildDetailChip('Signs', '${category.totalSigns}', AdminTheme.accentPink),
                const SizedBox(width: 8),
                _buildDetailChip('Level', '${category.requiredLevel}', AdminTheme.accentYellow),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditCategoryDialog(category);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.accentYellow, side: const BorderSide(color: AdminTheme.accentYellow)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _selectedCategoryId = category.id);
                      _tabController.animateTo(1);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                    style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accentYellow, foregroundColor: AdminTheme.primaryDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final descController = TextEditingController(text: category.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Category', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _dbService.updateCategory(category.id, {
                'name': nameController.text,
                'description': descController.text,
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accentYellow, foregroundColor: AdminTheme.primaryDark),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleCategoryAction(String action, CategoryModel category) async {
    if (action == 'edit') {
      _showEditCategoryDialog(category);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AdminTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Category?', style: TextStyle(color: Colors.white)),
          content: Text('Delete "${category.name}" and all its lessons?', style: const TextStyle(color: AdminTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _dbService.deleteCategory(category.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted!')));
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AdminTheme.accentYellow;
    }
  }
}
