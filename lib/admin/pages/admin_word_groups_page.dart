import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';

/// Admin Word Groups Management Page - CRUD operations for word groups and words
class AdminWordGroupsPage extends StatefulWidget {
  const AdminWordGroupsPage({super.key});

  @override
  State<AdminWordGroupsPage> createState() => _AdminWordGroupsPageState();
}

class _AdminWordGroupsPageState extends State<AdminWordGroupsPage> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();
  String? _selectedGroupId;
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
  Widget build(BuildContext context) {
    return Container(
      color: darkBlue,
      child: Row(
        children: [
          // Word Groups Sidebar
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: _buildGroupsSidebar(),
          ),
          // Words Content
          Expanded(child: _buildWordsContent()),
        ],
      ),
    );
  }

  Widget _buildGroupsSidebar() {
    return Column(
      children: [
        // Header with Add button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Word Groups',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showAddGroupDialog,
                icon: const Icon(Icons.add_circle_outline, color: accentGreen),
                tooltip: 'Add Word Group',
              ),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search groups...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ),
        // Groups List
        Expanded(
          child: StreamBuilder<List<WordGroupModel>>(
            stream: _adminDbService.wordGroupsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: accentYellow),
                );
              }

              var groups = snapshot.data!;

              if (_searchQuery.isNotEmpty) {
                groups = groups
                    .where((g) =>
                        g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        g.description.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              if (groups.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        color: Colors.white.withOpacity(0.3),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No word groups',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _buildGroupItem(group);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupItem(WordGroupModel group) {
    final isSelected = _selectedGroupId == group.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedGroupId = group.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? accentYellow.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: accentYellow.withOpacity(0.3)) : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.text_fields,
                    color: isSelected ? accentYellow : accentPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: TextStyle(
                          color: isSelected ? accentYellow : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${group.words.length} words • ${group.gemCost} gems',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.5),
                    size: 18,
                  ),
                  color: cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: accentRed))),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') _showEditGroupDialog(group);
                    if (value == 'delete') _confirmDeleteGroup(group);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordsContent() {
    if (_selectedGroupId == null) {
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
              'Select a word group to view words',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Words',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildToolbarButton(
                'Add Word',
                Icons.add_circle_outline,
                accentGreen,
                _showAddWordDialog,
              ),
            ],
          ),
        ),
        // Words List
        Expanded(child: _buildWordsList()),
      ],
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

  Widget _buildWordsList() {
    return StreamBuilder<List<WordModel>>(
      stream: _adminDbService.wordsStream(_selectedGroupId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: accentYellow),
          );
        }

        final words = snapshot.data!;

        if (words.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.text_snippet_outlined,
                  color: Colors.white.withOpacity(0.3),
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'No words in this group',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showAddWordDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Word'),
                  style: TextButton.styleFrom(foregroundColor: accentGreen),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: words.length,
          itemBuilder: (context, index) {
            final word = words[index];
            return _buildWordCard(word);
          },
        );
      },
    );
  }

  Widget _buildWordCard(WordModel word) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.text_fields, color: accentBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${word.characters.length} characters',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                if (word.characters.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: word.characters.map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.char,
                          style: const TextStyle(
                            color: accentPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5)),
            color: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: accentRed))),
            ],
            onSelected: (value) {
              if (value == 'edit') _showEditWordDialog(word);
              if (value == 'delete') _confirmDeleteWord(word);
            },
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showAddGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final gemCostController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Word Group', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, 'Group Name', Icons.folder_outlined),
            const SizedBox(height: 16),
            _buildTextField(descController, 'Description', Icons.description_outlined, maxLines: 2),
            const SizedBox(height: 16),
            _buildTextField(gemCostController, 'Gem Cost', Icons.diamond_outlined),
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
                final group = WordGroupModel(
                  id: '',
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  gemCost: int.tryParse(gemCostController.text) ?? 10,
                  order: 0,
                  words: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await _adminDbService.createWordGroup(group);
                if (mounted) Navigator.pop(context);
                _showSnackBar('Word group created', accentGreen);
              } catch (e) {
                _showSnackBar('Error: $e', accentRed);
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

  void _showEditGroupDialog(WordGroupModel group) {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);
    final gemCostController = TextEditingController(text: group.gemCost.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Word Group', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, 'Group Name', Icons.folder_outlined),
            const SizedBox(height: 16),
            _buildTextField(descController, 'Description', Icons.description_outlined, maxLines: 2),
            const SizedBox(height: 16),
            _buildTextField(gemCostController, 'Gem Cost', Icons.diamond_outlined),
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
                final updated = group.copyWith(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  gemCost: int.tryParse(gemCostController.text) ?? group.gemCost,
                  updatedAt: DateTime.now(),
                );
                await _adminDbService.updateWordGroup(updated);
                if (mounted) Navigator.pop(context);
                _showSnackBar('Word group updated', accentGreen);
              } catch (e) {
                _showSnackBar('Error: $e', accentRed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(WordGroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Word Group', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${group.name}"?\nThis will also delete all words in this group.',
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
                await _adminDbService.deleteWordGroup(group.id);
                if (mounted) {
                  Navigator.pop(context);
                  if (_selectedGroupId == group.id) {
                    setState(() => _selectedGroupId = null);
                  }
                }
                _showSnackBar('Word group deleted', accentGreen);
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

  void _showAddWordDialog() {
    _showWordDialog(null);
  }

  void _showEditWordDialog(WordModel word) {
    _showWordDialog(word);
  }

  void _showWordDialog(WordModel? word) {
    final isEdit = word != null;
    final textController = TextEditingController(text: word?.text ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Edit Word' : 'Add Word',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(textController, 'Word Text', Icons.text_fields),
            const SizedBox(height: 12),
            Text(
              'Characters will be automatically split from the word',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.trim().isEmpty) return;
              try {
                final text = textController.text.trim();
                final characters = text.split('').map((char) {
                  return WordCharacter(char: char.toUpperCase());
                }).toList();

                final wordData = WordModel(
                  id: word?.id ?? '',
                  wordGroupId: _selectedGroupId!,
                  text: text,
                  characters: characters,
                  order: word?.order ?? 0,
                  createdAt: word?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (isEdit) {
                  await _adminDbService.updateWord(_selectedGroupId!, wordData);
                  _showSnackBar('Word updated', accentGreen);
                } else {
                  await _adminDbService.createWord(_selectedGroupId!, wordData);
                  _showSnackBar('Word created', accentGreen);
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

  void _confirmDeleteWord(WordModel word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Word', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${word.text}"?',
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
                await _adminDbService.deleteWord(_selectedGroupId!, word.id);
                if (mounted) Navigator.pop(context);
                _showSnackBar('Word deleted', accentGreen);
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
