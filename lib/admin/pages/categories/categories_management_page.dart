import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../widgets/admin_widgets.dart';
import '../../../models/app_models.dart';

class CategoriesManagementPage extends StatefulWidget {
  final AdminModel admin;

  const CategoriesManagementPage({super.key, required this.admin});

  @override
  State<CategoriesManagementPage> createState() =>
      _CategoriesManagementPageState();
}

class _CategoriesManagementPageState extends State<CategoriesManagementPage> {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCategoriesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCategoryDialog(),
        backgroundColor: AdminTheme.accentYellow,
        foregroundColor: AdminTheme.primaryDark,
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
          const Text(
            'Categories',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage learning categories with auto-calculated totals',
            style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    hintStyle: const TextStyle(
                        color: AdminTheme.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        size: 20, color: AdminTheme.textSecondary),
                    filled: true,
                    fillColor: AdminTheme.cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _dbService.recalculateAllCategoryTotals(),
                icon: const Icon(Icons.calculate_outlined, color: AdminTheme.accentYellow),
                tooltip: 'Recalculate all totals',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _dbService.categoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AdminTheme.error, size: 40),
                  const SizedBox(height: 12),
                  Text('Error loading categories', style: const TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${snapshot.error}', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.category_outlined,
            title: 'No Categories Yet',
            subtitle: 'Create your first learning category',
            action: ElevatedButton.icon(
              onPressed: () => _showCreateCategoryDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Category'),
            ),
          );
        }

        final query = _searchController.text.toLowerCase();
        final categories = snapshot.data!.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.description.toLowerCase().contains(query);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) =>
              _buildCategoryCard(categories[index]),
        );
      },
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(category.iconUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                                child: Text(category.iconEmoji,
                                    style: const TextStyle(fontSize: 24)))))
                    : Center(
                        child: Text(category.iconEmoji,
                            style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(category.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AdminTheme.textPrimary)),
                        ),
                        if (category.isLocked)
                          const Icon(Icons.lock,
                              size: 14, color: AdminTheme.accentYellow),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(category.description,
                        style: const TextStyle(
                            fontSize: 11, color: AdminTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMiniChip(
                            Icons.book, '${category.totalLessons} lessons', color),
                        const SizedBox(width: 8),
                        _buildMiniChip(Icons.sign_language,
                            '${category.totalSigns} signs', color),
                        const SizedBox(width: 8),
                        _buildMiniChip(Icons.star,
                            'Lv ${category.requiredLevel}', AdminTheme.accentYellow),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AdminTheme.textSecondary, size: 20),
                onSelected: (action) =>
                    _handleCategoryAction(action, category),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'recalculate', child: Text('Recalculate Totals')),
                  const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final levelCtrl = TextEditingController(text: '1');
    String selectedEmoji = '📚';
    bool isLocked = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title:
              const Text('New Category', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedEmoji,
                  dropdownColor: AdminTheme.cardBg,
                  decoration: const InputDecoration(labelText: 'Icon Emoji'),
                  items: [
                    '📚', '👋', '🔢', '🔤', '👨‍👩‍👧‍👦', '🌈', '🐾',
                    '⭐', '🏫', '🎓', '💬', '🤝', '🎯', '🌍'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedEmoji = v ?? selectedEmoji),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: levelCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Required Level',
                    labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Locked',
                      style: TextStyle(color: AdminTheme.textPrimary, fontSize: 14)),
                  subtitle: const Text(
                      'Require learners to reach the required level',
                      style: TextStyle(
                          color: AdminTheme.textSecondary, fontSize: 11)),
                  value: isLocked,
                  activeColor: AdminTheme.accentYellow,
                  onChanged: (v) => setDialogState(() => isLocked = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final category = CategoryModel(
                  id: nameCtrl.text
                      .toLowerCase()
                      .replaceAll(' ', '_')
                      .replaceAll(RegExp(r'[^a-z0-9_]'), ''),
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  iconEmoji: selectedEmoji,
                  color: '#4A90D9',
                  order: 0,
                  totalLessons: 0,
                  totalSigns: 0,
                  isLocked: isLocked,
                  requiredLevel: int.tryParse(levelCtrl.text) ?? 1,
                );
                final result = await _dbService.createCategory(category);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category created!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to create category. Check Firestore rules.'), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.accentYellow,
                  foregroundColor: AdminTheme.primaryDark),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDetails(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(category.iconEmoji,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(category.description,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AdminTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildDetailStat(
                      'Lessons', '${category.totalLessons}', AdminTheme.info),
                  const SizedBox(width: 8),
                  _buildDetailStat('Signs', '${category.totalSigns}',
                      AdminTheme.accentPink),
                  const SizedBox(width: 8),
                  _buildDetailStat('Level', '${category.requiredLevel}',
                      AdminTheme.accentYellow),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDetailStat(
                      'Locked',
                      category.isLocked ? 'Yes' : 'No',
                      category.isLocked
                          ? AdminTheme.warning
                          : AdminTheme.success),
                  const SizedBox(width: 8),
                  _buildDetailStat(
                      'Order', '${category.order}', AdminTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: Container()),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditCategoryDialog(category);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.accentYellow,
                          side: const BorderSide(
                              color: AdminTheme.accentYellow)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _dbService
                            .recalculateCategoryTotals(category.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Totals recalculated!')));
                        }
                      },
                      icon: const Icon(Icons.calculate, size: 16),
                      label: const Text('Recalculate'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.accentYellow,
                          foregroundColor: AdminTheme.primaryDark),
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

  Widget _buildDetailStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    final nameCtrl = TextEditingController(text: category.name);
    final descCtrl = TextEditingController(text: category.description);
    final levelCtrl =
        TextEditingController(text: '${category.requiredLevel}');
    bool isLocked = category.isLocked;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Category',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: levelCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Required Level'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Locked',
                      style: TextStyle(
                          color: AdminTheme.textPrimary, fontSize: 14)),
                  value: isLocked,
                  activeColor: AdminTheme.accentYellow,
                  onChanged: (v) => setDialogState(() => isLocked = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final success = await _dbService.updateCategory(category.id, {
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'requiredLevel': int.tryParse(levelCtrl.text) ?? 1,
                  'isLocked': isLocked,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category updated!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update category.'), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.accentYellow,
                  foregroundColor: AdminTheme.primaryDark),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCategoryAction(String action, CategoryModel category) async {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'recalculate':
        await _dbService.recalculateCategoryTotals(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Totals recalculated!')));
        }
        break;
      case 'delete':
        final confirmed = await AdminConfirmDialog.show(
          context: context,
          title: 'Delete Category?',
          message:
              'Delete "${category.name}" and all its lessons? This cannot be undone.',
          confirmText: 'Delete',
          isDangerous: true,
        );
        if (confirmed) {
          await _dbService.deleteCategory(category.id);
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Category deleted!')));
          }
        }
        break;
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
