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
  String _type = 'alphabet'; // 'alphabet', 'numeric', 'both'
  bool _isActive = false;
  bool _isSaving = false;
  
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
    _type = l.type;
    _isActive = l.isActive;
    _orderCtrl.text = '${l.order}';
    _xpCtrl.text = '${l.xpReward}';
    _gemsCtrl.text = '${l.gemsReward}';
    _coinsCtrl.text = '${l.coinsReward}';
    _selectedCategoryId = l.categoryId;
    _selectedSigns = List<AdminSignItem>.from(l.signs);
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
      setState(() {
        _categories = cats.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
        _allSigns = allSigns;
        _loadingSupport = false;
        
        if (_selectedCategoryId.isEmpty && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
          _updateNextOrder(_selectedCategoryId);
        } else if (_selectedCategoryId.isNotEmpty) {
          if (!_isEdit) _updateNextOrder(_selectedCategoryId);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSupport = false);
    }
  }

  Future<void> _updateNextOrder(String catId) async {
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
       AdminToast.show(context, 'Please select at least one sign.', type: AdminToastType.error);
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
      type: _type,
      isActive: _isActive,
      order: int.tryParse(_orderCtrl.text) ?? 1,
      xpReward: int.tryParse(_xpCtrl.text) ?? 25,
      gemsReward: int.tryParse(_gemsCtrl.text) ?? 5,
      coinsReward: int.tryParse(_coinsCtrl.text) ?? 50,
      signs: _selectedSigns,
      testTypes: _isEdit ? widget.existingLesson!.testTypes : ['mcq', 'recall', 'matching'],
      createdBy: _isEdit ? widget.existingLesson!.createdBy : widget.admin.uid,
      createdAt: _isEdit ? widget.existingLesson!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool ok;
    if (_isEdit) {
      ok = await _db.updateLesson(_selectedCategoryId, lesson.id, lesson.toFirestore());
    } else {
      final id = await _db.createLesson(lesson);
      ok = id != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      AdminToast.show(context, _isEdit ? 'Lesson updated.' : 'Lesson created.', type: AdminToastType.success);
      Navigator.of(context).pop();
    } else {
      AdminToast.show(context, 'Failed to save. Try again.', type: AdminToastType.error);
    }
  }

  void _toggleSign(String char) {
    setState(() {
      final normalizedChar = (char.toUpperCase() == '0' || char.toUpperCase() == 'O') ? 'O' : char.toUpperCase();
      
      final exists = _selectedSigns.indexWhere((s) {
        final existingNorm = (s.character.toUpperCase() == '0' || s.character.toUpperCase() == 'O') ? 'O' : s.character.toUpperCase();
        return existingNorm == normalizedChar;
      });

      if (exists != -1) {
        _selectedSigns.removeAt(exists);
      } else {
        // Find matching data from master collection
        final signData = _allSigns.where((s) {
          final sWordNorm = (s.word.toUpperCase() == '0' || s.word.toUpperCase() == 'O') ? 'O' : s.word.toUpperCase();
          return sWordNorm == normalizedChar;
        }).firstOrNull;

        _selectedSigns.add(AdminSignItem(
          character: char.toUpperCase(),
          order: _selectedSigns.length,
          pictureUrl: signData?.imageUrl,
          animationUrl: signData?.gifUrl,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    if (_loadingSupport) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: AdminTopBar(title: 'Lesson Creator', variant: AdminTopBarVariant.sub),
        body: AdminSkeletonLoader.listRows(count: 15),
      );
    }

    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: _isEdit ? 'Edit Lesson' : 'New Lesson',
        variant: AdminTopBarVariant.sub,
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
                                label: cat.id,
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = cat.id;
                                    _updateNextOrder(cat.id);
                                  });
                                },
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

            // Category Type (Big Icons)
            Container(
              color: c.bgSurface,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CATEGORY TYPE', style: adminLabel(c.textMuted)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _TypeBox(
                        label: 'Alphabets',
                        icon: LucideIcons.type,
                        isSelected: _type == 'alphabet',
                        onTap: () => setState(() => _type = 'alphabet'),
                      )),
                      const SizedBox(width: 7),
                      Expanded(child: _TypeBox(
                        label: 'Numbers',
                        icon: LucideIcons.hash,
                        isSelected: _type == 'numeric',
                        onTap: () => setState(() => _type = 'numeric'),
                      )),
                      const SizedBox(width: 7),
                      Expanded(child: _TypeBox(
                        label: 'Both',
                        icon: LucideIcons.layers,
                        isSelected: _type == 'both',
                        onTap: () => setState(() => _type = 'both'),
                      )),
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
                    Text('${_selectedSigns.length} selected', style: adminLabel(c.accent)),
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
                      Expanded(child: AdminInput(label: 'XP', hint: '25', controller: _xpCtrl, keyboardType: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: AdminInput(label: 'GEMS', hint: '5', controller: _gemsCtrl, keyboardType: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: AdminInput(label: 'COINS', hint: '50', controller: _coinsCtrl, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AdminRow(
                    title: Text('Lesson Order', style: adminH3(c.textPrimary)),
                    subtitle: Text('Position in category list (max + 1)', style: adminMeta(c.textSecondary)),
                    trailing: Text('#${_orderCtrl.text}', style: adminH2(c.accent)),
                  ),
                  AdminRow(
                    title: Text('Publish Lesson', style: adminH3(c.textPrimary)),
                    subtitle: Text('Visible to learners', style: adminMeta(c.textSecondary)),
                    trailing: Switch.adaptive(
                      value: _isActive, 
                      activeTrackColor: c.accent,
                      onChanged: (v) => setState(() => _isActive = v)
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
                  _ReadinessItem(label: 'Title entered', isDone: _titleCtrl.text.isNotEmpty),
                  _ReadinessItem(label: 'Signs selected (${_selectedSigns.length})', isDone: _selectedSigns.isNotEmpty),
                  _ReadinessItem(label: 'Rewards configured', isDone: _xpCtrl.text.isNotEmpty && _gemsCtrl.text.isNotEmpty),
                  _ReadinessItem(label: 'Category assigned', isDone: _selectedCategoryId.isNotEmpty, isLast: true),
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
    List<String> pool = [];
    if (_type == 'alphabet' || _type == 'both') {
      pool.addAll('ABCDEFGHIJKLMNPQRSTUVWXYZ'.split('')); // Exclude O to handle 0/O as one
      pool.add('O / 0');
    }
    if (_type == 'numeric') {
      pool.addAll('123456789'.split(''));
      pool.add('O / 0');
    } else if (_type == 'both') {
       pool.addAll('123456789'.split(''));
    }

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
          final searchChar = isO0 ? 'O' : char;

          final isSelected = _selectedSigns.any((s) {
             final sNorm = (s.character.toUpperCase() == '0' || s.character.toUpperCase() == 'O') ? 'O' : s.character.toUpperCase();
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
                      style: signLetter(isSelected ? c.accent : c.textPrimary).copyWith(fontSize: isO0 ? 11 : 14),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      bottom: 6,
                      left: 0, right: 0,
                      child: Center(
                        child: Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent),
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

class _TypeBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeBox({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? c.accentFill : c.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? c.accent : c.border2,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? c.accent : c.textMuted),
            const SizedBox(height: 6),
            Text(
              label,
              style: adminLabel(isSelected ? c.accent : c.textMuted).copyWith(fontSize: 9),
            ),
          ],
        ),
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
        border: isLast ? null : Border(bottom: BorderSide(color: c.bgBase, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? c.successFill : (c.isDark ? c.bgSurface3 : c.bgSurface2),
            ),
            child: Center(
              child: isDone 
                ? Icon(LucideIcons.check, size: 10, color: c.successText)
                : Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.textMuted.withValues(alpha: 0.3), width: 1))),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: adminBody(isDone ? c.textPrimary : c.textMuted).copyWith(fontWeight: isDone ? FontWeight.w600 : FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

