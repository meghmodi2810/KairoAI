import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_inputs.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';
import 'package:kairo_ai/admin/widgets/a_overlays.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairo_ai/models/app_models.dart';
import 'package:kairo_ai/models/lesson_category.dart';

class LessonCreatorScreen extends StatefulWidget {
  final AdminModel admin;
  final AdminLessonModel? existingLesson;

  const LessonCreatorScreen({
    super.key,
    required this.admin,
    this.existingLesson,
  });

  @override
  State<LessonCreatorScreen> createState() => _LessonCreatorScreenState();
}

class _LessonCreatorScreenState extends State<LessonCreatorScreen> {
  final _db = AdminDatabaseService();

  // Form controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  final _xpCtrl = TextEditingController();
  final _gemsCtrl = TextEditingController();
  final _coinsCtrl = TextEditingController();

  String _selectedCategoryId = '';
  bool _isActive = false;
  bool _isSaving = false;
  bool _orderEditedByAdmin = false;

  // List of signs picked for THIS lesson
  List<AdminSignItem> _selectedSigns = [];

  // Reference of ALL signs from Firestore to get icons/gifs
  List<AdminSignModel> _allSigns = [];
  bool _loadingSupport = true;
  List<CategoryModel> _categories = [];

  String? _titleError;

  bool get _isEdit => widget.existingLesson != null;

  @override
  void initState() {
    super.initState();
    _prefillFromExisting();
    _loadSupportData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _xpCtrl.dispose();
    _gemsCtrl.dispose();
    _coinsCtrl.dispose();
    super.dispose();
  }

  void _prefillFromExisting() {
    final l = widget.existingLesson;
    if (l == null) {
      _xpCtrl.text = '25';
      _gemsCtrl.text = '5';
      _coinsCtrl.text = '50';
      _orderCtrl.text = '1';
      return;
    }
    _titleCtrl.text = l.title;
    _descCtrl.text = l.description;
    _isActive = l.isActive;
    _orderCtrl.text = '${l.order}';
    _xpCtrl.text = '${l.xpReward}';
    _gemsCtrl.text = '${l.gemsReward}';
    _coinsCtrl.text = '${l.coinsReward}';
    _selectedCategoryId =
        normalizeLessonCategoryId(l.categoryId) ??
        classifyLessonCategoryFromSigns(
          l.signs.map((sign) => sign.character),
          fallbackCategoryId: l.categoryId,
        );
    _selectedSigns = List<AdminSignItem>.from(l.signs);
    _orderEditedByAdmin = true;
  }

  CategoryModel _categoryFromDefinition(LessonCategoryDefinition definition) {
    return CategoryModel(
      id: definition.id,
      name: definition.label,
      description: definition.description,
      iconEmoji: definition.iconEmoji,
      color: definition.color,
      order: definition.order,
      totalLessons: 0,
      totalSigns: 0,
    );
  }

  CategoryModel _categoryFromDocument(
    DocumentSnapshot doc,
    LessonCategoryDefinition definition,
  ) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return CategoryModel(
      id: definition.id,
      name: data['name']?.toString() ?? definition.label,
      description: data['description']?.toString() ?? definition.description,
      iconUrl: data['iconUrl'] as String?,
      iconEmoji: data['iconEmoji']?.toString() ?? definition.iconEmoji,
      color: data['color']?.toString() ?? definition.color,
      order: (data['order'] as num?)?.toInt() ?? definition.order,
      totalLessons: (data['totalLessons'] as num?)?.toInt() ?? 0,
      totalSigns: (data['totalSigns'] as num?)?.toInt() ?? 0,
      isLocked: data['isLocked'] == true,
      requiredLevel: (data['requiredLevel'] as num?)?.toInt() ?? 1,
    );
  }

  List<CategoryModel> _canonicalCategories(QuerySnapshot snapshot) {
    final byCanonicalId = <String, DocumentSnapshot>{};
    for (final doc in snapshot.docs) {
      final canonicalId = normalizeLessonCategoryId(doc.id);
      if (canonicalId == null) continue;
      if (byCanonicalId.containsKey(canonicalId) &&
          doc.id != canonicalId) {
        continue;
      }
      byCanonicalId[canonicalId] = doc;
    }

    return kLessonCategoryDefinitions.map((definition) {
      final doc = byCanonicalId[definition.id];
      if (doc == null) return _categoryFromDefinition(definition);
      return _categoryFromDocument(doc, definition);
    }).toList(growable: false);
  }

  Future<void> _loadSupportData() async {
    setState(() => _loadingSupport = true);
    try {
      final cats = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .get();
      final allSigns = await _db.getAllSigns();

      if (!mounted) return;
      var shouldSuggestOrder = false;
      String categoryForSuggestion = _selectedCategoryId;

      setState(() {
        _categories = _canonicalCategories(cats);
        _allSigns = allSigns;
        _loadingSupport = false;

        if (_selectedCategoryId.isEmpty && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
          categoryForSuggestion = _selectedCategoryId;
          shouldSuggestOrder = true;
        } else if (_selectedCategoryId.isNotEmpty) {
          if (!_isEdit) {
            categoryForSuggestion = _selectedCategoryId;
            shouldSuggestOrder = true;
          }
        }
      });

      if (shouldSuggestOrder) {
        await _updateNextOrder(categoryForSuggestion, force: !_isEdit);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSupport = false);
    }
  }

  Future<void> _updateNextOrder(String catId, {bool force = false}) async {
    if (_orderEditedByAdmin && !force) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(catId)
          .collection('lessons')
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      int next = 1;
      if (snapshot.docs.isNotEmpty) {
        next = (snapshot.docs.first.data()['order'] as int? ?? 0) + 1;
      }

      if (mounted) {
        setState(() => _orderCtrl.text = '$next');
      }
    } catch (e) {
      debugPrint('Error fetching next order: $e');
    }
  }

  bool _validate() {
    setState(() => _titleError = null);
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Title is required');
      return false;
    }
    if (_selectedCategoryId.isEmpty) return false;
    if (_selectedSigns.isEmpty) {
      AdminToast.show(
        context,
        'Please select at least one sign.',
        type: AdminToastType.error,
      );
      return false;
    }
    final invalidSigns = invalidLessonSignsForCategory(
      _selectedCategoryId,
      _selectedSigns.map((sign) => sign.character),
    );
    if (invalidSigns.isNotEmpty) {
      AdminToast.show(
        context,
        'Remove incompatible signs for ${lessonCategoryLabel(_selectedCategoryId)}: ${invalidSigns.join(', ')}.',
        type: AdminToastType.error,
      );
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate() || _isSaving) return;
    setState(() => _isSaving = true);

    final lesson = AdminLessonModel(
      id: _isEdit ? widget.existingLesson!.id : '',
      categoryId: _selectedCategoryId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isActive: _isActive,
      order: int.tryParse(_orderCtrl.text) ?? 1,
      xpReward: int.tryParse(_xpCtrl.text) ?? 25,
      gemsReward: int.tryParse(_gemsCtrl.text) ?? 5,
      coinsReward: int.tryParse(_coinsCtrl.text) ?? 50,
      signs: _selectedSigns,
      testTypes: _isEdit
          ? widget.existingLesson!.testTypes
          : ['matching', 'recall', 'mcq'],
      createdBy: _isEdit ? widget.existingLesson!.createdBy : widget.admin.uid,
      createdAt: _isEdit ? widget.existingLesson!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool ok;
    if (_isEdit) {
      ok = await _db.updateLesson(
        _selectedCategoryId,
        lesson.id,
        lesson.toFirestore(),
        previousCategoryId: widget.existingLesson!.categoryId,
      );
    } else {
      final id = await _db.createLesson(lesson);
      ok = id != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      AdminToast.show(
        context,
        _isEdit ? 'Lesson updated.' : 'Lesson created.',
        type: AdminToastType.success,
      );
      Navigator.of(context).pop();
    } else {
      AdminToast.show(
        context,
        'Failed to save. Try again.',
        type: AdminToastType.error,
      );
    }
  }

  AdminSignItem _signWithOrder(AdminSignItem sign, int order) {
    return AdminSignItem(
      character: normalizeLessonSignLabel(sign.character),
      order: order,
      pictureUrl: sign.pictureUrl,
      animationUrl: sign.animationUrl,
      description: sign.description,
    );
  }

  List<AdminSignItem> _reindexSigns(Iterable<AdminSignItem> signs) {
    final list = signs.toList(growable: false);
    return List<AdminSignItem>.generate(
      list.length,
      (index) => _signWithOrder(list[index], index),
    );
  }

  void _selectCategory(String categoryId) {
    final canonicalCategoryId =
        normalizeLessonCategoryId(categoryId) ?? LessonCategoryIds.alphaNumeric;
    final keptSigns = _selectedSigns.where(
      (sign) =>
          isSignAllowedForLessonCategory(canonicalCategoryId, sign.character),
    );
    final prunedSigns = _reindexSigns(keptSigns);
    final removedCount = _selectedSigns.length - prunedSigns.length;

    setState(() {
      _selectedCategoryId = canonicalCategoryId;
      _selectedSigns = prunedSigns;
    });
    _updateNextOrder(canonicalCategoryId);

    if (removedCount > 0) {
      AdminToast.show(
        context,
        '$removedCount incompatible sign${removedCount == 1 ? '' : 's'} removed.',
        type: AdminToastType.info,
      );
    }
  }

  void _toggleSign(String char) {
    if (!isSignAllowedForLessonCategory(_selectedCategoryId, char)) {
      return;
    }

    setState(() {
      final normalizedChar = normalizeLessonSignLabel(char);

      final exists = _selectedSigns.indexWhere((s) {
        final existingNorm = normalizeLessonSignLabel(s.character);
        return existingNorm == normalizedChar;
      });

      if (exists != -1) {
        _selectedSigns.removeAt(exists);
      } else {
        // Find matching data from master collection
        final signData = _allSigns.where((s) {
          final sWordNorm = normalizeLessonSignLabel(s.word);
          return sWordNorm == normalizedChar;
        }).firstOrNull;

        _selectedSigns.add(
          AdminSignItem(
            character: normalizedChar,
            order: _selectedSigns.length,
            pictureUrl: signData?.imageUrl,
            animationUrl: signData?.gifUrl,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    if (_loadingSupport) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: AdminTopBar(
          title: 'Lesson Creator',
          variant: AdminTopBarVariant.sub,
          adminName: widget.admin.displayName,
          adminEmail: widget.admin.email,
        ),
        body: AdminSkeletonLoader.listRows(count: 15),
      );
    }

    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: _isEdit ? 'Edit Lesson' : 'New Lesson',
        variant: AdminTopBarVariant.sub,
        adminName: widget.admin.displayName,
        adminEmail: widget.admin.email,
        action: AdminTopBarSaveButton(
          onTap: _isSaving ? null : _save,
          isLoading: _isSaving,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Container(
              color: c.bgSurface,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  AdminInput(
                    label: 'TITLE',
                    hint: 'e.g. Basic Greetings',
                    controller: _titleCtrl,
                    errorText: _titleError,
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CATEGORY', style: adminLabel(c.textMuted)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, i) {
                            final cat = _categories[i];
                            final isSelected = cat.id == _selectedCategoryId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AdminFilterChip(
                                label: lessonCategoryLabel(cat.id),
                                selected: isSelected,
                                onTap: () => _selectCategory(cat.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // Select Signs Grid - revealed once category is picked
            if (_selectedCategoryId.isNotEmpty) ...[
              Container(
                color: c.bgBase,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SELECT SIGNS', style: adminLabel(c.textMuted)),
                    Text(
                      '${_selectedSigns.length} selected',
                      style: adminLabel(c.accent),
                    ),
                  ],
                ),
              ),
              _buildSignGrid(c),
              const Divider(),
            ],

            // Rewards
            AdminSectionHeader(title: 'Rewards & Status'),
            Container(
              color: c.bgSurface,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminInput(
                          label: 'XP',
                          hint: '25',
                          controller: _xpCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminInput(
                          label: 'GEMS',
                          hint: '5',
                          controller: _gemsCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminInput(
                          label: 'COINS',
                          hint: '50',
                          controller: _coinsCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AdminRow(
                    title: Text('Lesson Order', style: adminH3(c.textPrimary)),
                    subtitle: Text(
                      'Position in category list (max + 1)',
                      style: adminMeta(c.textSecondary),
                    ),
                    trailing: Text(
                      '#${_orderCtrl.text}',
                      style: adminH2(c.accent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AdminInput(
                    label: 'Manual Order Override',
                    hint: '1',
                    controller: _orderCtrl,
                    keyboardType: TextInputType.number,
                    helperText:
                        'If left unchanged, next order is suggested automatically.',
                    onChanged: (_) {
                      _orderEditedByAdmin = true;
                    },
                  ),
                  const SizedBox(height: 8),
                  AdminRow(
                    title: Text(
                      'Publish Lesson',
                      style: adminH3(c.textPrimary),
                    ),
                    subtitle: Text(
                      'Visible to learners',
                      style: adminMeta(c.textSecondary),
                    ),
                    trailing: Switch.adaptive(
                      value: _isActive,
                      activeTrackColor: c.accent,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const Divider(),

            // Readiness Checklist
            AdminSectionHeader(title: 'Readiness'),
            Container(
              color: c.bgSurface,
              child: Column(
                children: [
                  _ReadinessItem(
                    label: 'Title entered',
                    isDone: _titleCtrl.text.isNotEmpty,
                  ),
                  _ReadinessItem(
                    label: 'Signs selected (${_selectedSigns.length})',
                    isDone: _selectedSigns.isNotEmpty,
                  ),
                  _ReadinessItem(
                    label: 'Rewards configured',
                    isDone:
                        _xpCtrl.text.isNotEmpty && _gemsCtrl.text.isNotEmpty,
                  ),
                  _ReadinessItem(
                    label: 'Category assigned',
                    isDone: _selectedCategoryId.isNotEmpty,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const Divider(),

            Padding(
              padding: const EdgeInsets.all(14),
              child: AdminButton(
                label: _isEdit ? 'Update Lesson' : 'Publish lesson',
                onTap: _isSaving ? null : _save,
                isLoading: _isSaving,
                variant: AdminButtonVariant.accent,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSignGrid(AdminColors c) {
    final pool = lessonSignPoolLabelsForCategory(_selectedCategoryId);

    return Container(
      color: c.bgBase,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.0,
        ),
        itemCount: pool.length,
        itemBuilder: (context, i) {
          final char = pool[i];
          final bool isO0 = char == 'O / 0';
          final searchChar = normalizeLessonSignLabel(char);

          final isSelected = _selectedSigns.any((s) {
            final sNorm = normalizeLessonSignLabel(s.character);
            return sNorm == searchChar;
          });

          return GestureDetector(
            onTap: () => _toggleSign(searchChar),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected ? c.accentFill : c.bgSurface,
                borderRadius: BorderRadius.circular(radiusSignCell),
                border: Border.all(
                  color: isSelected ? c.accent : c.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      char,
                      textAlign: TextAlign.center,
                      style: signLetter(
                        isSelected ? c.accent : c.textPrimary,
                      ).copyWith(fontSize: isO0 ? 11 : 14),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      bottom: 6,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReadinessItem extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isLast;

  const _ReadinessItem({
    required this.label,
    required this.isDone,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: c.bgBase, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? c.successFill
                  : (c.isDark ? c.bgSurface3 : c.bgSurface2),
            ),
            child: Center(
              child: isDone
                  ? Icon(LucideIcons.check, size: 10, color: c.successText)
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.textMuted.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: adminBody(
              isDone ? c.textPrimary : c.textMuted,
            ).copyWith(fontWeight: isDone ? FontWeight.w600 : FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
