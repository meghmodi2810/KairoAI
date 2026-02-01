import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_models.dart';
import '../../widgets/admin_widgets.dart';

class WordGroupsManagementPage extends StatefulWidget {
  final AdminModel admin;

  const WordGroupsManagementPage({super.key, required this.admin});

  @override
  State<WordGroupsManagementPage> createState() => _WordGroupsManagementPageState();
}

class _WordGroupsManagementPageState extends State<WordGroupsManagementPage> {
  String? _selectedGroupId;

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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Word Groups', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                SizedBox(height: 2),
                Text('Manage premium word packs', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AdminTheme.accentYellow.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                Icon(Icons.diamond, color: AdminTheme.accentYellow, size: 14),
                SizedBox(width: 4),
                Text('Gems', style: TextStyle(color: AdminTheme.accentYellow, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('word_groups').orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow)));
        }

        final groups = snapshot.data?.docs ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 48, color: AdminTheme.textSecondary),
                const SizedBox(height: 12),
                const Text('No Word Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text('Create your first group', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateGroupDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Group'),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accentYellow, foregroundColor: AdminTheme.primaryDark),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final doc = groups[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildGroupCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unnamed';
    final gemCost = data['gemCost'] ?? 0;
    final description = data['description'] ?? '';
    final wordsCount = (data['words'] as List?)?.length ?? 0;
    final isSelected = _selectedGroupId == id;

    return GestureDetector(
      onTap: () => _showGroupDetails(id, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.cardBg.withOpacity(0.8) : AdminTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AdminTheme.accentYellow, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AdminTheme.accentPink, AdminTheme.primaryBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_special, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                  const SizedBox(height: 3),
                  Text(description.isNotEmpty ? description : 'No description', style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMiniChip('$wordsCount words', Icons.text_fields, AdminTheme.info),
                      const SizedBox(width: 6),
                      _buildMiniChip('$gemCost gems', Icons.diamond, AdminTheme.accentYellow),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AdminTheme.textSecondary, size: 18),
              onPressed: () => _showGroupOptions(id, data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showGroupDetails(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unnamed';
    final words = List<String>.from(data['words'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AdminTheme.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary))),
                    IconButton(
                      icon: const Icon(Icons.add, color: AdminTheme.accentYellow),
                      onPressed: () => _showAddWordDialog(id, words),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: AdminTheme.textSecondary, height: 1),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: words.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.text_fields, size: 40, color: AdminTheme.textSecondary),
                            SizedBox(height: 8),
                            Text('No words yet', style: TextStyle(fontSize: 14, color: AdminTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: words.length,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: AdminTheme.primaryDark, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(color: AdminTheme.info.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: AdminTheme.info, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(words[index], style: const TextStyle(fontSize: 13, color: AdminTheme.textPrimary))),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AdminTheme.error),
                                onPressed: () => _removeWord(id, words, index),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupOptions(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AdminTheme.info),
              title: const Text('Edit Group', style: TextStyle(color: AdminTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showEditGroupDialog(id, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AdminTheme.error),
              title: const Text('Delete Group', style: TextStyle(color: AdminTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteGroup(id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final gemController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Word Group', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gemController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Gem Cost', prefixIcon: Icon(Icons.diamond, color: AdminTheme.accentYellow, size: 18)),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('word_groups').add({
                  'name': nameController.text,
                  'description': descController.text,
                  'gemCost': int.tryParse(gemController.text) ?? 100,
                  'words': [],
                  'order': DateTime.now().millisecondsSinceEpoch,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accentYellow, foregroundColor: AdminTheme.primaryDark),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(String id, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final descController = TextEditingController(text: data['description'] ?? '');
    final gemController = TextEditingController(text: '${data['gemCost'] ?? 100}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Word Group', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gemController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Gem Cost', prefixIcon: Icon(Icons.diamond, color: AdminTheme.accentYellow, size: 18)),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('word_groups').doc(id).update({
                  'name': nameController.text,
                  'description': descController.text,
                  'gemCost': int.tryParse(gemController.text) ?? 100,
                });
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accentYellow, foregroundColor: AdminTheme.primaryDark),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddWordDialog(String groupId, List<String> currentWords) {
    final wordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Word', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: wordController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Word'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (wordController.text.isNotEmpty) {
                final updatedWords = [...currentWords, wordController.text];
                await FirebaseFirestore.instance.collection('word_groups').doc(groupId).update({'words': updatedWords});
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  _showGroupDetails(groupId, {'words': updatedWords});
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeWord(String groupId, List<String> words, int index) async {
    final updatedWords = [...words]..removeAt(index);
    await FirebaseFirestore.instance.collection('word_groups').doc(groupId).update({'words': updatedWords});
    if (mounted) {
      Navigator.pop(context);
      // Fetch fresh data
      final doc = await FirebaseFirestore.instance.collection('word_groups').doc(groupId).get();
      if (doc.exists) {
        _showGroupDetails(groupId, doc.data()!);
      }
    }
  }

  Future<void> _confirmDeleteGroup(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Group?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: AdminTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('word_groups').doc(id).delete();
    }
  }
}
