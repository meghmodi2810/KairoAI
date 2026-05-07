import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';
import 'package:kairo_ai/admin/widgets/a_overlays.dart';
import 'admin_word_group_detail_screen.dart';

class AdminWordsScreen extends StatefulWidget {
  final AdminModel admin;
  final VoidCallback onMenuTap;

  const AdminWordsScreen({
    super.key,
    required this.admin,
    required this.onMenuTap,
  });

  @override
  State<AdminWordsScreen> createState() => _AdminWordsScreenState();
}

class _AdminWordsScreenState extends State<AdminWordsScreen> {
  final _db = AdminDatabaseService();
  bool _actionLoading = false;

  Future<void> _deleteWordGroup(WordGroupModel group) async {
    if (_actionLoading) return;
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Delete "${group.name}"?',
      body: 'All words within this group will be deleted. This cannot be undone.',
      confirmLabel: 'Delete permanently',
    );
    if (!confirmed || !mounted) return;

    setState(() => _actionLoading = true);
    await _db.deleteWordGroup(group.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    AdminToast.show(context, '${group.name} deleted.', type: AdminToastType.success);
  }

  void _openGroupDetail({WordGroupModel? group}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminWordGroupDetailScreen(
          admin: widget.admin,
          existingGroup: group,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'Word Packs',
        onMenuTap: widget.onMenuTap,
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_actionLoading)
              const SizedBox(
                width: 48,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              AdminTopBarIconButton(
                icon: LucideIcons.plus,
                onTap: () => _openGroupDetail(),
              ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('word_groups')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AdminSkeletonLoader.listRows();
          }
          if (snapshot.hasError) {
            return AdminErrorState(
              message: 'Could not load word groups.',
              onRetry: () => setState(() {}),
            );
          }
          
          final docs = snapshot.data?.docs ?? [];
          final groups = docs.map((d) => WordGroupModel.fromFirestore(d)).toList();

          if (groups.isEmpty) {
            return AdminEmptyState(
              icon: LucideIcons.type,
              title: 'No word packs yet',
              body: 'Create your first word pack to get started.',
              actionLabel: 'Create pack',
              onAction: () => _openGroupDetail(),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: bottomBuf),
            children: [
              AdminSectionHeader(
                title: '${groups.length} word pack${groups.length == 1 ? '' : 's'}',
              ),
              ...groups.asMap().entries.map((e) {
                final i = e.key;
                final group = e.value;
                return _WordGroupRow(
                  group: group,
                  isLast: i == groups.length - 1,
                  onTap: () => _openGroupDetail(group: group),
                  onDelete: () => _deleteWordGroup(group),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _WordGroupRow extends StatelessWidget {
  final WordGroupModel group;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WordGroupRow({
    required this.group,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    Widget leading = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.accentFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Center(
        child: Text(
          group.iconEmoji,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );

    return Dismissible(
      key: Key('wordgroup_${group.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: c.errorFill,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.trash2, size: 18, color: c.error),
            const SizedBox(height: 2),
            Text('Delete', style: adminBodySm(c.error)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: AdminRow(
        leading: leading,
        title: Text(group.name, style: adminH3(c.textPrimary)),
        subtitle: Text(
          '${group.totalWords} words · ${group.unlockGemCost} gems',
          style: adminMeta(c.textSecondary),
        ),
        isLast: isLast,
        showChevron: true,
        onTap: onTap,
        minHeight: 60,
      ),
    );
  }
}
