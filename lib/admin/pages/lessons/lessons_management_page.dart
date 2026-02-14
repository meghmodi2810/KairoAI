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

class _LessonsManagementPageState extends State<LessonsManagementPage> {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = true;

  /// Cached global signs for the sign picker
  List<AdminSignModel> _globalSigns = [];
  bool _signsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadGlobalSigns();
  }

  Future<void> _loadGlobalSigns() async {
    final signs = await _dbService.getAllSigns();
    if (mounted) {
      setState(() {
        _globalSigns = signs;
        _signsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    _dbService.categoriesStream().listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories;
          if (_selectedCategoryId == null && categories.isNotEmpty) {
            _selectedCategoryId = categories.first.id;
          }
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(cs),
          _buildCategorySelector(cs),
          Expanded(child: _buildLessonsList(cs)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateLessonDialog,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lessons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text('Manage lessons per category', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadCategories,
                icon: _isLoading
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                    : const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search lessons...',
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14),
              prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurface.withOpacity(0.4)),
              filled: true,
              fillColor: cs.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(ColorScheme cs) {
    if (_isLoading || _categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              backgroundColor: cs.surface,
              selectedColor: cs.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: cs.onPrimary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonsList(ColorScheme cs) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    if (_selectedCategoryId == null) {
      return const EmptyState(
        icon: Icons.touch_app,
        title: 'Select Category',
        subtitle: 'Choose a category above',
      );
    }

    return StreamBuilder<List<AdminLessonModel>>(
      stream: _dbService.lessonsByCategoryStream(_selectedCategoryId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 40),
                  const SizedBox(height: 12),
                  Text('Error loading lessons', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${snapshot.error}', style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final query = _searchController.text.toLowerCase();
        final lessons = (snapshot.data ?? []).where((l) {
          return l.title.toLowerCase().contains(query) ||
              l.description.toLowerCase().contains(query);
        }).toList();

        if (lessons.isEmpty) {
          return EmptyState(
            icon: Icons.school_outlined,
            title: 'No Lessons',
            subtitle: 'Add a lesson to this category',
            action: ElevatedButton.icon(
              onPressed: _showCreateLessonDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Lesson'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lessons.length,
          itemBuilder: (context, index) => _buildLessonCard(lessons[index]),
        );
      },
    );
  }

  Widget _buildLessonCard(AdminLessonModel lesson) {
    final cs = Theme.of(context).colorScheme;
    final difficultyColors = {
      'Beginner': Colors.green,
      'Intermediate': Colors.orange,
      'Advanced': cs.error,
    };
    final color = difficultyColors[lesson.difficulty] ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showLessonDetails(lesson),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${lesson.unitNumber}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                    const SizedBox(height: 3),
                    Text(lesson.description, style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildChip(lesson.difficulty, color, cs),
                        const SizedBox(width: 6),
                        _buildChip(lesson.type, Colors.blue, cs),
                        const SizedBox(width: 6),
                        _buildChip('${lesson.signs.length} signs', cs.primary, cs),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: cs.onSurface.withOpacity(0.5), size: 18),
                onSelected: (action) => _handleLessonAction(action, lesson),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'mcq', child: Text('Generate MCQs')),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: cs.error))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _showCreateLessonDialog() {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category first')));
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: '1');
    final estMinCtrl = TextEditingController(text: '10');
    final coinsCtrl = TextEditingController(text: '50');
    final xpCtrl = TextEditingController(text: '100');
    String difficulty = 'Beginner';
    String type = 'alphabet';
    List<AdminSignModel> selectedSigns = [];

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Create Lesson'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Unit #', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: estMinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Est. Min', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                      items: ['Beginner', 'Intermediate', 'Advanced']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => difficulty = v ?? difficulty),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      items: ['alphabet', 'number', 'word', 'sentence']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => type = v ?? type),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: coinsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Coins', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: xpCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'XP', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── Sign Picker Section ──
                    _buildSignPickerSection(
                      cs: cs,
                      selectedSigns: selectedSigns,
                      type: type,
                      onChanged: (signs) => setDialogState(() => selectedSigns = signs),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  final now = DateTime.now();
                  final signItems = selectedSigns.asMap().entries.map((e) => AdminSignItem(
                    character: e.value.word,
                    animationUrl: e.value.gifUrl,
                    pictureUrl: e.value.imageUrl,
                    order: e.key,
                    description: e.value.description,
                  )).toList();

                  final lesson = AdminLessonModel(
                    id: '',
                    title: titleCtrl.text,
                    description: descCtrl.text,
                    categoryId: _selectedCategoryId!,
                    unitNumber: int.tryParse(unitCtrl.text) ?? 1,
                    type: type,
                    difficulty: difficulty,
                    estimatedMinutes: int.tryParse(estMinCtrl.text) ?? 10,
                    coinsReward: int.tryParse(coinsCtrl.text) ?? 50,
                    xpReward: int.tryParse(xpCtrl.text) ?? 100,
                    signs: signItems,
                    testTypes: ['mcq'],
                    order: 0,
                    isActive: true,
                    createdAt: now,
                    updatedAt: now,
                    createdBy: widget.admin.displayName,
                  );
                  final result = await _dbService.createLesson(lesson);
                  if (result != null) {
                    await _dbService.recalculateCategoryTotals(_selectedCategoryId!);
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lesson created with ${signItems.length} signs!')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create lesson.'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLessonDetails(AdminLessonModel lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(lesson.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(lesson.description, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildDetailChip('Unit ${lesson.unitNumber}', Colors.blue, cs),
                    const SizedBox(width: 8),
                    _buildDetailChip(lesson.difficulty, Colors.orange, cs),
                    const SizedBox(width: 8),
                    _buildDetailChip(lesson.type, cs.primary, cs),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDetailChip('${lesson.estimatedMinutes} min', Colors.blue, cs),
                    const SizedBox(width: 8),
                    _buildDetailChip('${lesson.coinsReward} coins', Colors.orange, cs),
                    const SizedBox(width: 8),
                    _buildDetailChip('${lesson.xpReward} XP', cs.primary, cs),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Signs (${lesson.signs.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 8),
                if (lesson.signs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('No signs added', style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 12))),
                  )
                else
                  ...lesson.signs.map((sign) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Text(sign.character, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        const Spacer(),
                        if (sign.pictureUrl != null)
                          Icon(Icons.image, size: 14, color: Colors.green)
                        else
                          Icon(Icons.image_not_supported, size: 14, color: cs.onSurface.withOpacity(0.3)),
                      ],
                    ),
                  )),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditLessonDialog(lesson);
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _generateMCQsForLesson(lesson);
                        },
                        icon: const Icon(Icons.quiz, size: 16),
                        label: const Text('Gen MCQs'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(String text, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _showEditLessonDialog(AdminLessonModel lesson) {
    final titleCtrl = TextEditingController(text: lesson.title);
    final descCtrl = TextEditingController(text: lesson.description);
    final unitCtrl = TextEditingController(text: '${lesson.unitNumber}');
    final estMinCtrl = TextEditingController(text: '${lesson.estimatedMinutes}');
    final coinsCtrl = TextEditingController(text: '${lesson.coinsReward}');
    final xpCtrl = TextEditingController(text: '${lesson.xpReward}');
    String difficulty = lesson.difficulty;
    String type = lesson.type;

    // Pre-populate selected signs from existing lesson signs
    List<AdminSignModel> selectedSigns = lesson.signs.map((signItem) {
      // Try to match with a global sign by character/word
      final match = _globalSigns.where((gs) => gs.word == signItem.character).firstOrNull;
      if (match != null) return match;
      // Fallback: create a placeholder AdminSignModel
      return AdminSignModel(
        id: '',
        word: signItem.character,
        description: signItem.description ?? '',
        imageUrl: signItem.pictureUrl,
        gifUrl: signItem.animationUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Lesson'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: unitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: estMinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Est. Min', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                      items: ['Beginner', 'Intermediate', 'Advanced'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setDialogState(() => difficulty = v ?? difficulty),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      items: ['alphabet', 'number', 'word', 'sentence'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setDialogState(() => type = v ?? type),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: coinsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Coins', border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: xpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'XP', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── Sign Picker Section ──
                    _buildSignPickerSection(
                      cs: cs,
                      selectedSigns: selectedSigns,
                      type: type,
                      onChanged: (signs) => setDialogState(() => selectedSigns = signs),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final signItems = selectedSigns.asMap().entries.map((e) => AdminSignItem(
                    character: e.value.word,
                    animationUrl: e.value.gifUrl,
                    pictureUrl: e.value.imageUrl,
                    order: e.key,
                    description: e.value.description,
                  )).toList();

                  final success = await _dbService.updateLesson(lesson.categoryId, lesson.id, {
                    'title': titleCtrl.text,
                    'description': descCtrl.text,
                    'subtitle': descCtrl.text,
                    'unitNumber': int.tryParse(unitCtrl.text) ?? 1,
                    'estimatedMinutes': int.tryParse(estMinCtrl.text) ?? 10,
                    'coinsReward': int.tryParse(coinsCtrl.text) ?? 50,
                    'xpReward': int.tryParse(xpCtrl.text) ?? 100,
                    'difficulty': difficulty,
                    'type': type,
                    'signs': signItems.map((s) => s.toMap()).toList(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lesson updated with ${signItems.length} signs!')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update lesson.'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Sign Picker Section (used in Create & Edit dialogs) ──

  Widget _buildSignPickerSection({
    required ColorScheme cs,
    required List<AdminSignModel> selectedSigns,
    required String type,
    required ValueChanged<List<AdminSignModel>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Signs (${selectedSigns.length})',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                final result = await _showSignSelectionDialog(
                  currentSelection: selectedSigns,
                  filterType: type,
                );
                if (result != null) {
                  onChanged(result);
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Signs'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (!_signsLoaded)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
                const SizedBox(width: 8),
                Text('Loading signs…', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
              ],
            ),
          )
        else if (selectedSigns.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.3), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.sign_language_outlined, size: 28, color: cs.onSurface.withOpacity(0.3)),
                const SizedBox(height: 6),
                Text('No signs added yet', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
                const SizedBox(height: 4),
                Text('Tap "Add Signs" to pick from the sign library', style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.3))),
              ],
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedSigns.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final item = selectedSigns.removeAt(oldIndex);
              selectedSigns.insert(newIndex, item);
              onChanged(List.from(selectedSigns));
            },
            itemBuilder: (context, index) {
              final sign = selectedSigns[index];
              return Container(
                key: ValueKey('${sign.id}_$index'),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 12, right: 4),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: sign.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(sign.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(sign.word, style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                              ),
                            ),
                          )
                        : Center(child: Text(sign.word, style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary))),
                  ),
                  title: Text(sign.word, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  subtitle: Text(sign.type, style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.5))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drag_handle, size: 18, color: cs.onSurface.withOpacity(0.3)),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: cs.error),
                        onPressed: () {
                          selectedSigns.removeAt(index);
                          onChanged(List.from(selectedSigns));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<List<AdminSignModel>?> _showSignSelectionDialog({
    required List<AdminSignModel> currentSelection,
    required String filterType,
  }) async {
    // Work with a copy so cancel doesn't affect original
    final selected = List<AdminSignModel>.from(currentSelection);
    final selectedIds = selected.map((s) => s.id).toSet();

    // Filter signs by type (alphabet/number) if needed
    List<AdminSignModel> availableSigns = List.from(_globalSigns);
    String searchQuery = '';
    String activeFilter = filterType; // Pre-select the lesson type as filter

    return showDialog<List<AdminSignModel>>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Apply search + type filter
            final filtered = availableSigns.where((s) {
              final matchesSearch = searchQuery.isEmpty ||
                  s.word.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  s.description.toLowerCase().contains(searchQuery.toLowerCase());
              final matchesType = activeFilter == 'all' || s.type == activeFilter;
              return matchesSearch && matchesType;
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Expanded(child: Text('Select Signs', style: TextStyle(fontSize: 16))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${selected.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search signs...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    // Type filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['all', 'alphabet', 'number'].map((t) {
                          final isActive = activeFilter == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(t == 'all' ? 'All' : t[0].toUpperCase() + t.substring(1), style: TextStyle(fontSize: 11)),
                              selected: isActive,
                              onSelected: (_) => setDialogState(() => activeFilter = isActive ? 'all' : t),
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Signs grid
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text('No signs found', style: TextStyle(color: cs.onSurface.withOpacity(0.4))))
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final sign = filtered[index];
                                final isSelected = selectedIds.contains(sign.id);
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      if (isSelected) {
                                        selected.removeWhere((s) => s.id == sign.id);
                                        selectedIds.remove(sign.id);
                                      } else {
                                        selected.add(sign);
                                        selectedIds.add(sign.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? cs.primary.withOpacity(0.12) : cs.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? cs.primary : cs.outlineVariant.withOpacity(0.3),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (sign.imageUrl != null)
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.network(sign.imageUrl!, fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Center(
                                                  child: Text(sign.word, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Text(sign.word, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          sign.word,
                                          style: TextStyle(fontSize: 9, color: cs.onSurface.withOpacity(0.6)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_circle, size: 14, color: cs.primary),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: Text('Done (${selected.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateMCQsForLesson(AdminLessonModel lesson) async {
    if (lesson.signs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson has no signs to generate MCQs from')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating MCQs...')));

    try {
      final mcqs = await _dbService.generateMCQsForLesson(lesson.signs);
      if (mcqs.isNotEmpty && mounted) {
        // Save MCQs to the lesson
        await _dbService.updateLesson(lesson.categoryId, lesson.id, {
          'mcqs': mcqs.map((m) => m.toMap()).toList(),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated ${mcqs.length} MCQs!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _handleLessonAction(String action, AdminLessonModel lesson) async {
    if (action == 'edit') {
      _showEditLessonDialog(lesson);
    } else if (action == 'mcq') {
      await _generateMCQsForLesson(lesson);
    } else if (action == 'delete') {
      final confirmed = await AdminConfirmDialog.show(
        context: context,
        title: 'Delete Lesson?',
        message: 'Delete "${lesson.title}"? This cannot be undone.',
        confirmText: 'Delete',
        isDangerous: true,
      );
      if (confirmed) {
        await _dbService.deleteLesson(lesson.categoryId, lesson.id);
        if (_selectedCategoryId != null) {
          await _dbService.recalculateCategoryTotals(_selectedCategoryId!);
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson deleted!')));
      }
    }
  }
}
