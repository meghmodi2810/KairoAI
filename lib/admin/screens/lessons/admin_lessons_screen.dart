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
import 'package:kairo_ai/admin/screens/lessons/lesson_creator_screen.dart';

class AdminLessonsScreen extends StatefulWidget {
  final AdminModel admin;
  final VoidCallback onMenuTap;

  const AdminLessonsScreen({
    super.key,
    required this.admin,
    required this.onMenuTap,
  });

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  final _db = AdminDatabaseService();
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  String _search = '';
  bool _actionLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesFilter(AdminLessonModel lesson) {
    if (_search.isNotEmpty) {
      if (!lesson.title.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
    }
    switch (_filter) {
      case 'Live':
        return lesson.isActive;
      case 'Draft':
        return !lesson.isActive;
      case 'Alphabets':
        return lesson.type == 'alphabet';
      case 'Numbers':
        return lesson.type == 'numeric';
      case 'Both':
        return lesson.type == 'both';
      default:
        return true;
    }
  }

  Future<void> _deleteLesson(AdminLessonModel lesson) async {
    if (_actionLoading) return;
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Delete "${lesson.title}"?',
      body: 'All learner progress for this lesson will be lost. This cannot be undone.',
      confirmLabel: 'Delete permanently',
    );
    if (!confirmed || !mounted) return;

    setState(() => _actionLoading = true);
    final ok = await _db.deleteLesson(lesson.categoryId, lesson.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (ok) {
      AdminToast.show(context, '${lesson.title} deleted.',
          type: AdminToastType.success);
    } else {
      AdminToast.show(context, 'Delete failed. Try again.',
          type: AdminToastType.error);
    }
  }

  void _openCreator({AdminLessonModel? lesson}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonCreatorScreen(
          admin: widget.admin,
          existingLesson: lesson,
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
        title: 'Lessons',
        onMenuTap: widget.onMenuTap,
        adminName: widget.admin.displayName,
        adminEmail: widget.admin.email,
        action: _actionLoading
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
                icon: LucideIcons.plus,
                onTap: () => _openCreator(),
              ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _openCreator(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: c.btnPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0),
            ],
          ),
          child: Icon(
            LucideIcons.plus,
            color: c.btnPrimaryFg,
            size: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: AdminSearchBar(
              controller: _searchCtrl,
              hint: 'Search lessons...',
              onChanged: (v) => setState(() => _search = v),
              onClear: () => setState(() => _search = ''),
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Live', 'Draft', 'Alphabets', 'Numbers', 'Both']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AdminFilterChip(
                        label: f,
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('lessons')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AdminSkeletonLoader.listRows();
                }
                if (snapshot.hasError) {
                  return AdminErrorState(
                    message: 'Could not load lessons.',
                    onRetry: () => setState(() {}),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                final lessons = docs
                    .map((d) => AdminLessonModel.fromFirestore(d))
                    .where(_matchesFilter)
                    .toList()
                  ..sort((a, b) => a.title.compareTo(b.title));

                if (lessons.isEmpty) {
                  return AdminEmptyState(
                    icon: LucideIcons.bookOpen,
                    title: 'No lessons yet',
                    body: 'Create your first lesson to get started.',
                    actionLabel: 'Create lesson',
                    onAction: () => _openCreator(),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: bottomBuf),
                  children: [
                    AdminSectionHeader(
                      title: '${lessons.length} lesson${lessons.length == 1 ? '' : 's'}',
                    ),
                    ...lessons.asMap().entries.map((e) {
                      final i = e.key;
                      final lesson = e.value;
                      return _LessonRow(
                        lesson: lesson,
                        isLast: i == lessons.length - 1,
                        onTap: () => _openCreator(lesson: lesson),
                        onDelete: () => _deleteLesson(lesson),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final AdminLessonModel lesson;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LessonRow({
    required this.lesson,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final typeLabel = lesson.type == 'alphabet'
        ? 'ALPHA'
        : lesson.type == 'numeric'
            ? 'NUMS'
            : 'BOTH';

    Widget leading = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.accentFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Center(
        child: Icon(LucideIcons.bookOpen, size: 16, color: c.isDark ? c.accentBright : c.accent),
      ),
    );

    Widget trailing = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminTag(
          label: lesson.isActive ? 'Live' : 'Draft',
          variant: lesson.isActive ? AdminTagVariant.live : AdminTagVariant.draft,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: c.accentFill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: c.border, width: 1.5),
          ),
          child: Text(
            typeLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: c.isDark ? c.accentBright : c.accent,
            ),
          ),
        ),
      ],
    );

    return Dismissible(
      key: Key('lesson_${lesson.id}'),
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
        return false; // We handle deletion in the callback
      },
      child: AdminRow(
        leading: leading,
        title: Text(lesson.title, style: adminH3(c.textPrimary)),
        subtitle: Text(
          'Lv ${lesson.order} · ${lesson.xpReward} XP · ${lesson.gemsReward} Gems',
          style: adminMeta(c.textSecondary),
        ),
        trailing: trailing,
        isLast: isLast,
        showChevron: true,
        onTap: onTap,
        minHeight: 60,
      ),
    );
  }
}
