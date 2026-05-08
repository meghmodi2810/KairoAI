import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';
import 'package:kairo_ai/admin/widgets/a_inputs.dart';
import 'package:kairo_ai/admin/widgets/a_overlays.dart';

class AdminIssuesScreen extends StatefulWidget {
  final AdminModel admin;
  final VoidCallback onMenuTap;

  const AdminIssuesScreen({
    super.key,
    required this.admin,
    required this.onMenuTap,
  });

  @override
  State<AdminIssuesScreen> createState() => _AdminIssuesScreenState();
}

class _AdminIssuesScreenState extends State<AdminIssuesScreen> {
  final _db = AdminDatabaseService();
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All';
  String? _selectedIssueId;
  bool _actionLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesIssue(IssueModel issue) {
    final issueStatus = issue.status.replaceAll('_', '-').toLowerCase();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      if (!issue.title.toLowerCase().contains(q) &&
          !issue.description.toLowerCase().contains(q) &&
          !issue.readableReporter.toLowerCase().contains(q)) {
        return false;
      }
    }
    switch (_statusFilter) {
      case 'Open':
        return issueStatus == 'open' || issueStatus == 'new';
      case 'In-progress':
        return issueStatus == 'in-progress';
      case 'Resolved':
        return issueStatus == 'resolved';
      case 'Closed':
        return issueStatus == 'closed';
      default:
        return true;
    }
  }

  Future<void> _updateStatus(IssueModel issue, String status) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    final ok = await _db.updateIssueStatus(issue.id, status);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (ok) {
      AdminToast.show(
        context,
        'Issue moved to ${status.replaceAll('-', ' ')}',
        type: AdminToastType.success,
      );
    } else {
      AdminToast.show(context, 'Status update failed', type: AdminToastType.error);
    }
  }

  Future<void> _deleteIssue(IssueModel issue) async {
    if (_actionLoading) return;
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Delete issue?',
      body: 'This action is permanent and will remove all associated admin notes.',
      confirmLabel: 'Delete issue',
    );
    if (!confirmed || !mounted) return;
    setState(() => _actionLoading = true);
    final ok = await _db.deleteIssue(issue.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    AdminToast.show(
      context,
      ok ? 'Issue permanently deleted' : 'Deletion failed',
      type: ok ? AdminToastType.success : AdminToastType.error,
    );
  }

  void _openDetail(IssueModel issue) {
    setState(() => _selectedIssueId = issue.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _IssueDetailSheet(
          issue: issue,
          admin: widget.admin,
          onStatusChange: (s) => _updateStatus(issue, s),
          onDelete: () {
            Navigator.of(sheetContext).pop();
            _deleteIssue(issue);
          },
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedIssueId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'Issues',
        onMenuTap: widget.onMenuTap,
        adminName: widget.admin.displayName,
        adminEmail: widget.admin.email,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AdminSearchBar(
              controller: _searchCtrl,
              hint: 'Search issues or reports...',
              onChanged: (v) => setState(() => _search = v),
              onClear: () => setState(() => _search = ''),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Open', 'In-progress', 'Resolved', 'Closed']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AdminFilterChip(
                        label: f,
                        selected: _statusFilter == f,
                        onTap: () => setState(() => _statusFilter = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<IssueModel>>(
              stream: _db.issuesStream(
                  status: (_statusFilter == 'All' || _statusFilter == 'Open') 
                      ? null 
                      : _statusFilter.toLowerCase()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AdminSkeletonLoader.listRows(count: 8);
                }
                if (snapshot.hasError) {
                  return AdminErrorState(onRetry: () => setState(() {}));
                }
                
                final issues = (snapshot.data ?? [])
                    .where(_matchesIssue)
                    .toList();

                if (issues.isEmpty) {
                  return AdminEmptyState(
                    icon: LucideIcons.checkCircle,
                    title: _search.isNotEmpty ? 'No matches' : 'No active issues',
                    body: _search.isNotEmpty 
                        ? 'Try clearing your search filters.' 
                        : 'Perfect! There are no pending reports at the moment.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: bottomBuf),
                  itemCount: issues.length,
                  itemBuilder: (context, i) {
                    final issue = issues[i];
                    return _IssueRow(
                      issue: issue,
                      isSelected: _selectedIssueId == issue.id,
                      isLast: i == issues.length - 1,
                      onTap: () => _openDetail(issue),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final IssueModel issue;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  const _IssueRow({
    required this.issue,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final normalizedStatus = issue.status.replaceAll('_', '-').toLowerCase();
    AdminTagVariant statusVariant;
    switch (normalizedStatus) {
      case 'resolved':
        statusVariant = AdminTagVariant.active;
      case 'in-progress':
        statusVariant = AdminTagVariant.pending;
      case 'closed':
        statusVariant = AdminTagVariant.inactive;
      case 'new':
      case 'open':
      default:
        statusVariant = AdminTagVariant.draft;
    }

    final isCritical = issue.priority == 'critical' || issue.priority == 'high';

    return AdminRow(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isCritical ? c.errorFill : c.bgSurface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            isCritical ? LucideIcons.alertTriangle : LucideIcons.info, 
            size: 16, 
            color: isCritical ? c.error : c.textMuted,
          ),
        ),
      ),
      title: Text(
        issue.title,
        style: adminH3(c.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(issue.description, style: adminMeta(c.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            'Reporter: ${issue.readableReporter}',
            style: TextStyle(fontSize: 10, color: c.textMuted, fontWeight: FontWeight.w600),
          ),
          if (issue.sourceScreen.isNotEmpty || issue.lessonId != null || issue.signLabel != null)
            Text(
              'Context: ${issue.sourceScreen.isNotEmpty ? issue.sourceScreen : 'unknown'}${issue.lessonId != null ? ' · lesson ${issue.lessonId}' : ''}${issue.signLabel != null ? ' · sign ${issue.signLabel}' : ''}',
              style: TextStyle(fontSize: 10, color: c.textMuted, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AdminTag(label: normalizedStatus.toUpperCase(), variant: statusVariant),
          const SizedBox(height: 4),
          Text(
            issue.priority.toUpperCase(),
            style: TextStyle(
              fontSize: 9, 
              fontWeight: FontWeight.w800, 
              color: isCritical ? c.error : c.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      showChevron: true,
      isLast: isLast,
      onTap: onTap,
      minHeight: 76,
    );
  }
}

class _IssueDetailSheet extends StatefulWidget {
  final IssueModel issue;
  final AdminModel admin;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onDelete;

  const _IssueDetailSheet({
    required this.issue,
    required this.admin,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  State<_IssueDetailSheet> createState() => _IssueDetailSheetState();
}

class _IssueDetailSheetState extends State<_IssueDetailSheet> {
  final _db = AdminDatabaseService();
  final _noteCtrl = TextEditingController();
  bool _addingNote = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.issue.status.replaceAll('_', '-').toLowerCase();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    if (_noteCtrl.text.trim().isEmpty) return;
    setState(() => _addingNote = true);
    final note = AdminNote(
      adminId: widget.admin.uid,
      adminName: widget.admin.displayName.isNotEmpty
          ? widget.admin.displayName
          : widget.admin.email,
      content: _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
    );
    final ok = await _db.addIssueNote(widget.issue.id, note);
    setState(() => _addingNote = false);
    if (!mounted) return;
    if (ok) {
      _noteCtrl.clear();
      AdminToast.show(context, 'Internal note added');
    } else {
      AdminToast.show(context, 'Failed to save note', type: AdminToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final issue = widget.issue;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Material(
        color: c.bgSurface,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(issue.title, style: adminH2(c.textPrimary)),
                              const SizedBox(height: 4),
                              Text('Reported: ${issue.readableReporter}', style: adminMeta(c.textMuted)),
                              if (issue.reporterEmail.isNotEmpty)
                                Text(issue.reporterEmail, style: adminMeta(c.textMuted)),
                              if (issue.sourceScreen.isNotEmpty || issue.contextType.isNotEmpty)
                                Text(
                                  'Context: ${issue.sourceScreen.isNotEmpty ? issue.sourceScreen : 'n/a'} · ${issue.contextType.isNotEmpty ? issue.contextType : 'general'}',
                                  style: adminMeta(c.textMuted),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AdminTag(label: issue.priority, variant: AdminTagVariant.inactive),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(issue.description, style: adminBody(c.textSecondary)),
                    ),
                    const SizedBox(height: 20),
                    Text('WORKFLOW STATUS', style: adminLabel(c.textMuted)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['open', 'in-progress', 'resolved', 'closed']
                            .map((s) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AdminFilterChip(
                                    label: s.toUpperCase(),
                                    selected: _currentStatus == s,
                                    onTap: () {
                                      setState(() => _currentStatus = s);
                                      widget.onStatusChange(s);
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('INTERNAL NOTES (${issue.adminNotes.length})', style: adminLabel(c.textMuted)),
                    const SizedBox(height: 8),
                    if (issue.adminNotes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No admin notes recorded.', style: adminBodySm(c.textMuted)),
                      )
                    else
                      ...issue.adminNotes.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: c.border),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.content, style: adminBodySm(c.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text('${n.adminName} · Just now', style: adminMeta(c.textMuted)),
                                ],
                              ),
                            ),
                          )),
                    const SizedBox(height: 12),
                    AdminInput(
                      label: 'Resolution note',
                      hint: 'Add a resolution note...',
                      controller: _noteCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AdminButton(
                            label: 'Add Note',
                            variant: AdminButtonVariant.secondary,
                            onTap: _addingNote ? null : _addNote,
                            isLoading: _addingNote,
                          ),
                        ),
                        const SizedBox(width: 12),
                        AdminButton(
                          label: 'Delete',
                          variant: AdminButtonVariant.ghost,
                          fullWidth: false,
                          onTap: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
          const SizedBox(height: 12),
          AdminInput(
            label: 'Resolution note',
            hint: 'Add a resolution note...',
            controller: _noteCtrl,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AdminButton(
                  label: 'Add Note',
                  variant: AdminButtonVariant.secondary,
                  onTap: _addingNote ? null : _addNote,
                  isLoading: _addingNote,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminButton(
                  label: 'Delete',
                  variant: AdminButtonVariant.ghost,
                  onTap: widget.onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
