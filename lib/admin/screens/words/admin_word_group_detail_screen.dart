import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';
import 'package:kairo_ai/admin/widgets/a_inputs.dart';
import 'package:kairo_ai/admin/widgets/a_overlays.dart';

class AdminWordGroupDetailScreen extends StatefulWidget {
  final AdminModel admin;
  final WordGroupModel? existingGroup;

  const AdminWordGroupDetailScreen({
    super.key,
    required this.admin,
    this.existingGroup,
  });

  @override
  State<AdminWordGroupDetailScreen> createState() => _AdminWordGroupDetailScreenState();
}

class _AdminWordGroupDetailScreenState extends State<AdminWordGroupDetailScreen> {
  final _db = AdminDatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _emojiCtrl;
  late TextEditingController _unlockCostCtrl;
  late TextEditingController _rewardCtrl;
  late TextEditingController _orderCtrl;
  
  String _difficulty = 'beginner';
  bool _isSaving = false;
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _groupId = widget.existingGroup?.id;
    _nameCtrl = TextEditingController(text: widget.existingGroup?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existingGroup?.description ?? '');
    _emojiCtrl = TextEditingController(text: widget.existingGroup?.iconEmoji ?? '📝');
    _unlockCostCtrl = TextEditingController(text: (widget.existingGroup?.unlockGemCost ?? 0).toString());
    _rewardCtrl = TextEditingController(text: (widget.existingGroup?.completionGemReward ?? 0).toString());
    _orderCtrl = TextEditingController(text: (widget.existingGroup?.order ?? 0).toString());
    if (widget.existingGroup != null) {
      _difficulty = widget.existingGroup!.difficulty;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _emojiCtrl.dispose();
    _unlockCostCtrl.dispose();
    _rewardCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AdminToast.show(context, 'Name is required', type: AdminToastType.error);
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final unlockCost = int.tryParse(_unlockCostCtrl.text) ?? 0;
      final reward = int.tryParse(_rewardCtrl.text) ?? 0;
      final order = int.tryParse(_orderCtrl.text) ?? 0;

      if (_groupId == null) {
        final group = WordGroupModel(
          id: '',
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          iconEmoji: _emojiCtrl.text.trim(),
          difficulty: _difficulty,
          unlockGemCost: unlockCost,
          completionGemReward: reward,
          order: order,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _groupId = await _db.createWordGroup(group);
      } else {
        final group = widget.existingGroup!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          iconEmoji: _emojiCtrl.text.trim(),
          difficulty: _difficulty,
          unlockGemCost: unlockCost,
          completionGemReward: reward,
          order: order,
          updatedAt: DateTime.now(),
        );
        await _db.updateWordGroup(group.id, group.toFirestore());
      }
      
      if (!mounted) return;
      AdminToast.show(context, 'Word pack saved!', type: AdminToastType.success);
      if (widget.existingGroup == null) {
        // If it was newly created, force a rebuild to show the words list
        setState(() {});
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      AdminToast.show(context, 'Error saving: $e', type: AdminToastType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showWordEditor({WordModel? word}) {
    if (_groupId == null) return;
    
    final textCtrl = TextEditingController(text: word?.text ?? '');
    final orderCtrl = TextEditingController(text: (word?.order ?? 0).toString());
    bool isSavingWord = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final c = ac(context);
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: c.bgBase,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(color: c.border, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(word == null ? 'Add Word' : 'Edit Word', style: adminH2(c.textPrimary)),
                    const SizedBox(height: 16),
                    AdminInput(
                      controller: textCtrl,
                      label: 'Word Text',
                      hint: 'e.g. HELLO',
                    ),
                    const SizedBox(height: 12),
                    AdminInput(
                      controller: orderCtrl,
                      label: 'Order',
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    AdminButton(
                      label: isSavingWord ? 'Saving...' : 'Save Word',
                      onTap: () async {
                        if (isSavingWord) return;
                        final text = textCtrl.text.trim().toUpperCase();
                        if (text.isEmpty) return;
                        
                        setModalState(() => isSavingWord = true);
                        try {
                          final newWord = WordModel(
                            id: word?.id ?? '',
                            wordGroupId: _groupId!,
                            text: text,
                            normalizedText: text,
                            characters: text.split('').map((char) => WordCharacter(char: char)).toList(),
                            order: int.tryParse(orderCtrl.text) ?? 0,
                            createdAt: word?.createdAt ?? DateTime.now(),
                          );
                          
                          if (word == null) {
                            await _db.addWord(_groupId!, newWord);
                          } else {
                            await _db.updateWord(_groupId!, newWord.id, newWord.toFirestore());
                          }
                          if (!mounted) return;
                          Navigator.pop(context);
                          AdminToast.show(context, 'Word saved.', type: AdminToastType.success);
                        } catch (e) {
                          AdminToast.show(context, e.toString(), type: AdminToastType.error);
                        } finally {
                          setModalState(() => isSavingWord = false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _deleteWord(String wordId) async {
    try {
      await _db.deleteWord(_groupId!, wordId);
      if (!mounted) return;
      AdminToast.show(context, 'Word deleted.', type: AdminToastType.success);
    } catch (e) {
      if (!mounted) return;
      AdminToast.show(context, 'Error deleting word: $e', type: AdminToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final isEditing = _groupId != null;
    
    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: isEditing ? 'Edit Pack' : 'New Pack',
        variant: AdminTopBarVariant.sub,
        action: _isSaving
            ? const SizedBox(
                width: 48,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : AdminTopBarIconButton(
                icon: LucideIcons.save,
                onTap: _save,
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminInput(
                      controller: _nameCtrl,
                      label: 'Pack Name',
                      hint: 'e.g. Greetings',
                    ),
                    const SizedBox(height: 16),
                    AdminInput(
                      controller: _descCtrl,
                      label: 'Description',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AdminInput(
                            controller: _emojiCtrl,
                            label: 'Emoji Icon',
                            hint: '📝',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AdminInput(
                            controller: _orderCtrl,
                            label: 'Order',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Difficulty', style: adminLabel(c.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: c.border, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _difficulty,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          dropdownColor: c.bgSurface,
                          items: ['beginner', 'intermediate', 'advanced'].map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(d.toUpperCase(), style: adminBody(c.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _difficulty = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AdminInput(
                            controller: _unlockCostCtrl,
                            label: 'Unlock Gem Cost',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AdminInput(
                            controller: _rewardCtrl,
                            label: 'Completion Reward',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_groupId != null) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Words in Pack', style: adminH2(c.textPrimary)),
                    AdminButton(
                      label: 'Add Word',
                      icon: LucideIcons.plus,
                      onTap: _showWordEditor,
                      height: 32,
                      fullWidth: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('word_groups')
                      .doc(_groupId)
                      .collection('words')
                      .orderBy('order')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return AdminSkeletonLoader.listRows();
                    final words = snapshot.data!.docs.map((d) => WordModel.fromFirestore(d)).toList();
                    
                    if (words.isEmpty) {
                      return AdminEmptyState(
                        icon: LucideIcons.type,
                        title: 'No words',
                        body: 'Add the first word to this pack.',
                        actionLabel: 'Add Word',
                        onAction: _showWordEditor,
                      );
                    }
                    
                    return Column(
                      children: words.map((word) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AdminRow(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c.bgSurface2,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: c.border),
                              ),
                              alignment: Alignment.center,
                              child: Text('${word.order}', style: adminMeta(c.textSecondary)),
                            ),
                            title: Text(word.text, style: adminH3(c.textPrimary)),
                            trailing: IconButton(
                              icon: Icon(LucideIcons.trash2, color: c.error, size: 18),
                              onPressed: () => _deleteWord(word.id),
                            ),
                            onTap: () => _showWordEditor(word: word),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
