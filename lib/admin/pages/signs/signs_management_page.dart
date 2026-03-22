import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../widgets/admin_widgets.dart';

class SignsManagementPage extends StatefulWidget {
  final AdminModel admin;

  const SignsManagementPage({super.key, required this.admin});

  @override
  State<SignsManagementPage> createState() => _SignsManagementPageState();
}

class _SignsManagementPageState extends State<SignsManagementPage>
    with SingleTickerProviderStateMixin {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
                _buildSignsGrid('alphabet'),
                _buildSignsGrid('number'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSignDialog,
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
          const Text('Signs',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text(
              'Manage ISL signs — images auto-resolve from local assets',
              style:
                  TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search signs...',
              hintStyle: const TextStyle(
                  color: AdminTheme.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AdminTheme.textSecondary),
              filled: true,
              fillColor: AdminTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
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
          color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(10)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
            color: AdminTheme.accentYellow,
            borderRadius: BorderRadius.circular(10)),
        labelColor: AdminTheme.primaryDark,
        unselectedLabelColor: AdminTheme.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Alphabets'),
          Tab(text: 'Numbers'),
        ],
      ),
    );
  }

  Widget _buildSignsGrid(String type) {
    return StreamBuilder<List<AdminSignModel>>(
      stream: _dbService.signsByTypeStream(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AdminTheme.accentYellow)));
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
                  Text('Error loading signs', style: const TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${snapshot.error}', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: type == 'alphabet'
                ? Icons.abc
                : Icons.onetwothree,
            title: 'No ${type == 'alphabet' ? 'Alphabet' : 'Number'} Signs',
            subtitle: 'Add signs to get started',
            action: ElevatedButton.icon(
              onPressed: _showCreateSignDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Sign'),
            ),
          );
        }

        final query = _searchController.text.toLowerCase();
        final signs = snapshot.data!.where((s) {
          return s.word.toLowerCase().contains(query) ||
              s.description.toLowerCase().contains(query);
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: signs.length,
          itemBuilder: (context, index) => _buildSignCard(signs[index]),
        );
      },
    );
  }

  Widget _buildSignCard(AdminSignModel sign) {
    final hasImage = sign.imageUrl != null || sign.gifUrl != null;

    return GestureDetector(
      onTap: () => _showSignDetails(sign),
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage
                ? AdminTheme.success.withOpacity(0.3)
                : AdminTheme.warning.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasImage)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AdminTheme.primaryDark,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    sign.gifUrl ?? sign.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(sign.word,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AdminTheme.accentYellow)),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AdminTheme.primaryDark,
                ),
                child: Center(
                  child: Text(sign.word,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.accentYellow)),
                ),
              ),
            const SizedBox(height: 6),
            Text(sign.word,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textPrimary)),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (hasImage ? AdminTheme.success : AdminTheme.warning)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hasImage ? 'Has Image' : 'No Image',
                style: TextStyle(
                  fontSize: 8,
                  color:
                      hasImage ? AdminTheme.success : AdminTheme.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSignDialog() {
    final wordCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = _tabController.index == 0 ? 'alphabet' : 'number';
    bool isAutoChecking = false;
    String? autoFoundUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Sign',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: wordCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Word (letter or number) *',
                    labelStyle:
                        TextStyle(color: AdminTheme.textSecondary),
                    hintText: 'e.g. A, B, 1, 2',
                    hintStyle: TextStyle(color: AdminTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle:
                        TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  dropdownColor: AdminTheme.cardBg,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'alphabet', child: Text('Alphabet')),
                    DropdownMenuItem(
                        value: 'number', child: Text('Number')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => type = v ?? type),
                ),
                const SizedBox(height: 16),
                // Auto-detect button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isAutoChecking
                        ? null
                        : () async {
                            if (wordCtrl.text.isEmpty) return;
                            setDialogState(
                                () => isAutoChecking = true);
                            final url = await _dbService
                                .findSignImageInStorage(
                                    wordCtrl.text.trim().toUpperCase());
                            setDialogState(() {
                              isAutoChecking = false;
                              autoFoundUrl = url;
                            });
                          },
                    icon: isAutoChecking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Icon(Icons.image_search, size: 16),
                    label: Text(isAutoChecking
                        ? 'Checking Storage...'
                        : 'Auto-detect Image from Storage'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.accentYellow,
                      side: const BorderSide(
                          color: AdminTheme.accentYellow),
                    ),
                  ),
                ),
                if (autoFoundUrl != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminTheme.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AdminTheme.success, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Image found in Storage!',
                              style: TextStyle(
                                  color: AdminTheme.success,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (autoFoundUrl == null &&
                    !isAutoChecking &&
                    wordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No image found. You can upload one after creating the sign.',
                    style: TextStyle(
                        color: AdminTheme.textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (wordCtrl.text.isEmpty) return;
                final now = DateTime.now();
                final sign = AdminSignModel(
                  id: '',
                  word: wordCtrl.text.trim().toUpperCase(),
                  description: descCtrl.text,
                  imageUrl: autoFoundUrl,
                  type: type,
                  order: 0,
                  createdAt: now,
                  updatedAt: now,
                );
                final result = await _dbService.createSign(sign);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign created!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to create sign. Check Firestore rules.'), backgroundColor: Colors.red));
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

  void _showSignDetails(AdminSignModel sign) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            // Sign preview
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AdminTheme.primaryDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: sign.imageUrl != null || sign.gifUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        sign.gifUrl ?? sign.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(sign.word,
                              style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AdminTheme.accentYellow)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(sign.word,
                          style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AdminTheme.accentYellow)),
                    ),
            ),
            const SizedBox(height: 16),
            Text(sign.word,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textPrimary)),
            if (sign.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(sign.description,
                  style: const TextStyle(
                      fontSize: 13, color: AdminTheme.textSecondary)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatusBadge(status: sign.type, small: true),
                const SizedBox(width: 8),
                StatusBadge(
                  status: sign.imageUrl != null ? 'Has Image' : 'No Image',
                  color: sign.imageUrl != null
                      ? AdminTheme.success
                      : AdminTheme.warning,
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditSignDialog(sign);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.accentYellow,
                        side: const BorderSide(
                            color: AdminTheme.accentYellow)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final url = await _dbService
                          .findSignImageInStorage(sign.word);
                      if (url != null) {
                        await _dbService.updateSign(
                            sign.id, {'imageUrl': url});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Image auto-assigned!')));
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('No image found in Storage')));
                        }
                      }
                    },
                    icon: const Icon(Icons.image_search, size: 16),
                    label: const Text('Auto-find'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.info,
                        side: const BorderSide(color: AdminTheme.info)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final confirmed = await AdminConfirmDialog.show(
                      context: context,
                      title: 'Delete Sign?',
                      message:
                          'Delete the sign "${sign.word}"? This cannot be undone.',
                      confirmText: 'Delete',
                      isDangerous: true,
                    );
                    if (confirmed) {
                      await _dbService.deleteSign(sign.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Sign deleted!')));
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: AdminTheme.error),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditSignDialog(AdminSignModel sign) {
    final wordCtrl = TextEditingController(text: sign.word);
    final descCtrl = TextEditingController(text: sign.description);
    final imageUrlCtrl = TextEditingController(text: sign.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('Edit Sign', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Word'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Image URL (auto or manual)'),
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
              final success = await _dbService.updateSign(sign.id, {
                'word': wordCtrl.text.trim().toUpperCase(),
                'description': descCtrl.text,
                'imageUrl':
                    imageUrlCtrl.text.isEmpty ? null : imageUrlCtrl.text,
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign updated!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update sign.'), backgroundColor: Colors.red));
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
    );
  }
}
