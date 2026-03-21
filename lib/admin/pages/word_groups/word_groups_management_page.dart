import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../widgets/admin_widgets.dart';

class WordGroupsManagementPage extends StatefulWidget {
  final AdminModel admin;

  const WordGroupsManagementPage({super.key, required this.admin});

  @override
  State<WordGroupsManagementPage> createState() =>
      _WordGroupsManagementPageState();
}

class _WordGroupsManagementPageState extends State<WordGroupsManagementPage> {
  final AdminDatabaseService _dbService = AdminDatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildGroupsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(),
        backgroundColor: AdminTheme.accentYellow,
        child: const Icon(Icons.add, color: AdminTheme.primaryDark),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Word Groups',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textPrimary)),
                SizedBox(height: 2),
                Text('Manage premium word packs with auto-splitting',
                    style: TextStyle(
                        fontSize: 12, color: AdminTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AdminTheme.accentYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.diamond, color: AdminTheme.accentYellow, size: 14),
                SizedBox(width: 4),
                Text('Gems',
                    style: TextStyle(
                        color: AdminTheme.accentYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Groups List ─────────────────────────────────────────────
  Widget _buildGroupsList() {
    return StreamBuilder<List<WordGroupModel>>(
      stream: _dbService.wordGroupsStream(),
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
                  Text('Error loading word groups', style: const TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${snapshot.error}', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return EmptyState(
            icon: Icons.folder_open,
            title: 'No Word Groups',
            subtitle: 'Create your first group',
            action: ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Group'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.accentYellow,
                  foregroundColor: AdminTheme.primaryDark),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: groups.length,
          itemBuilder: (_, i) => _buildGroupCard(groups[i]),
        );
      },
    );
  }

  // ─── Group Card ──────────────────────────────────────────────
  Widget _buildGroupCard(WordGroupModel group) {
    return GestureDetector(
      onTap: () => _showGroupDetails(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AdminTheme.accentPink, AdminTheme.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_special,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                      group.description.isNotEmpty
                          ? group.description
                          : 'No description',
                      style: const TextStyle(
                          fontSize: 11, color: AdminTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  _buildMiniChip('${group.gemCost} gems', Icons.diamond,
                      AdminTheme.accentYellow),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AdminTheme.textSecondary, size: 18),
              onSelected: (a) => _handleGroupAction(a, group),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Group Details (bottom sheet with word subcollection) ────
  void _showGroupDetails(WordGroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
              color: AdminTheme.cardBg,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              // drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AdminTheme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
              // title row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AdminTheme.textPrimary)),
                          Text('${group.gemCost} gems',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AdminTheme.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add,
                          color: AdminTheme.accentYellow),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddWordDialog(group);
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child:
                    Divider(color: AdminTheme.textSecondary, height: 1),
              ),
              const SizedBox(height: 8),
              // words from subcollection stream
              Expanded(
                child: StreamBuilder<List<WordModel>>(
                  stream: _dbService.wordsStream(group.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AdminTheme.accentYellow)));
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text('Error: ${snap.error}', style: const TextStyle(color: AdminTheme.error, fontSize: 12)),
                      );
                    }
                    final words = snap.data ?? [];
                    if (words.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.text_fields,
                                size: 40,
                                color: AdminTheme.textSecondary),
                            SizedBox(height: 8),
                            Text('No words yet',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AdminTheme.textSecondary)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: words.length,
                      itemBuilder: (_, i) =>
                          _buildWordTile(group.id, words[i], i),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Single word tile with character chips ───────────────────
  Widget _buildWordTile(String groupId, WordModel word, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: AdminTheme.primaryDark,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: AdminTheme.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: Text('${index + 1}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AdminTheme.info,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(word.text,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary))),
              // Auto-split button
              IconButton(
                icon: const Icon(Icons.auto_fix_high,
                    size: 16, color: AdminTheme.accentYellow),
                tooltip: 'Auto-split into characters',
                onPressed: () => _autoSplitWord(groupId, word),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AdminTheme.error),
                onPressed: () => _removeWord(groupId, word.id),
              ),
            ],
          ),
          // Character breakdown
          if (word.characters.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: word.characters
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.signReference != null
                              ? AdminTheme.success.withOpacity(0.15)
                              : AdminTheme.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: c.signReference != null
                                ? AdminTheme.success.withOpacity(0.3)
                                : AdminTheme.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Text(c.char,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: c.signReference != null
                                    ? AdminTheme.success
                                    : AdminTheme.warning)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Auto-split a word ───────────────────────────────────────
  Future<void> _autoSplitWord(String groupId, WordModel word) async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Splitting word into characters…')));

    try {
      final characters = await _dbService.splitWordIntoCharacters(word.text);

      await _dbService.updateWord(groupId, word.id, {
        'characters': characters.map((c) => c.toMap()).toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Split "${word.text}" into ${characters.length} characters')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ─── Action router ──────────────────────────────────────────
  void _handleGroupAction(String action, WordGroupModel group) {
    if (action == 'edit') {
      _showEditGroupDialog(group);
    } else if (action == 'delete') {
      _confirmDeleteGroup(group);
    }
  }

  // ─── Create Group Dialog ────────────────────────────────────
  void _showCreateGroupDialog() {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final gemC = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Word Group',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nameC,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Group Name')),
            const SizedBox(height: 10),
            TextField(
                controller: descC,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            TextField(
                controller: gemC,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Gem Cost',
                    prefixIcon: Icon(Icons.diamond,
                        color: AdminTheme.accentYellow, size: 18)),
                keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameC.text.isEmpty) return;
              final group = WordGroupModel(
                id: '',
                name: nameC.text,
                description: descC.text,
                gemCost: int.tryParse(gemC.text) ?? 100,
                order: DateTime.now().millisecondsSinceEpoch,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              final result = await _dbService.createWordGroup(group);
              if (mounted) {
                Navigator.pop(context);
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group created!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create group. Check Firestore rules.'), backgroundColor: Colors.red));
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
    );
  }

  // ─── Edit Group Dialog ──────────────────────────────────────
  void _showEditGroupDialog(WordGroupModel group) {
    final nameC = TextEditingController(text: group.name);
    final descC = TextEditingController(text: group.description);
    final gemC = TextEditingController(text: '${group.gemCost}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Word Group',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nameC,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Group Name')),
            const SizedBox(height: 10),
            TextField(
                controller: descC,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            TextField(
                controller: gemC,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Gem Cost',
                    prefixIcon: Icon(Icons.diamond,
                        color: AdminTheme.accentYellow, size: 18)),
                keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _dbService.updateWordGroup(group.id, {
                'name': nameC.text,
                'description': descC.text,
                'gemCost': int.tryParse(gemC.text) ?? 100,
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Updated!')));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.accentYellow,
                foregroundColor: AdminTheme.primaryDark),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── Add Word Dialog (with auto-split toggle) ───────────────
  void _showAddWordDialog(WordGroupModel group) {
    final wordC = TextEditingController();
    bool autoSplit = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title:
              const Text('Add Word', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: wordC,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Word'),
                autofocus: true),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto-split into characters',
                  style: TextStyle(
                      color: AdminTheme.textPrimary, fontSize: 13)),
              subtitle: const Text('Validates against signs collection',
                  style: TextStyle(
                      color: AdminTheme.textSecondary, fontSize: 10)),
              value: autoSplit,
              onChanged: (v) => setDialogState(() => autoSplit = v),
              activeColor: AdminTheme.accentYellow,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (wordC.text.isEmpty) return;

                List<WordCharacter> characters = [];
                if (autoSplit) {
                  characters = await _dbService
                      .splitWordIntoCharacters(wordC.text.trim());
                }

                final newWord = WordModel(
                  id: '',
                  wordGroupId: group.id,
                  text: wordC.text.trim(),
                  characters: characters,
                  order: DateTime.now().millisecondsSinceEpoch,
                  createdAt: DateTime.now(),
                );

                await _dbService.addWord(group.id, newWord);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Added "${wordC.text}" with ${characters.length} characters')));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.success),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Remove word ────────────────────────────────────────────
  Future<void> _removeWord(String groupId, String wordId) async {
    await _dbService.deleteWord(groupId, wordId);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Word removed')));
    }
  }

  // ─── Delete group ───────────────────────────────────────────
  Future<void> _confirmDeleteGroup(WordGroupModel group) async {
    final confirmed = await AdminConfirmDialog.show(
      context: context,
      title: 'Delete Group?',
      message: 'Delete "${group.name}"? This cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    );
    if (confirmed) {
      await _dbService.deleteWordGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Deleted!')));
      }
    }
  }
}
