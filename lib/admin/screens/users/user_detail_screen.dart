import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';
import 'package:kairo_ai/admin/widgets/a_inputs.dart';
import 'package:kairo_ai/admin/widgets/a_overlays.dart';
import 'package:kairo_ai/models/app_models.dart';

class UserDetailScreen extends StatefulWidget {
  final AdminModel admin;
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.admin,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _db = AdminDatabaseService();
  UserModel? _user;
  List<LessonProgress> _progress = [];
  bool _loading = true;
  bool _hasError = false;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final user = await _db.getLearner(widget.userId);
      final progress = await _db.getLearnerProgress(widget.userId);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
        return;
      }
      setState(() {
        _user = user;
        _progress = progress;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  Future<void> _toggleStatus() async {
    if (_user == null || _actionLoading) return;
    final newActive = !_user!.isActive;
    final confirmed = await AdminConfirmModal.show(
      context,
      title: '${newActive ? 'Activate' : 'Deactivate'} this account?',
      body: newActive
          ? 'This user will regain access to the app.'
          : 'This user will be blocked from using the app.',
      confirmLabel: newActive ? 'Activate' : 'Deactivate',
    );
    if (!confirmed || !mounted) return;

    setState(() => _actionLoading = true);
    final ok = await _db.setLearnerStatus(widget.userId, newActive);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (ok) {
      await _loadUser();
      if (!mounted) return;
      AdminToast.show(
        context,
        'Account ${newActive ? 'activated' : 'deactivated'}.',
        type: AdminToastType.success,
      );
    } else {
      AdminToast.show(
        context,
        'Action failed. Try again.',
        type: AdminToastType.error,
      );
    }
  }

  Future<void> _resetProgress() async {
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Reset all progress?',
      body: 'This will delete all lesson completions, XP, gems, and streaks. This cannot be undone.',
      confirmLabel: 'Reset progress',
    );
    if (!confirmed || !mounted) return;

    setState(() => _actionLoading = true);
    final ok = await _db.resetLearnerProgress(widget.userId);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (ok) {
      await _loadUser();
      if (!mounted) return;
      AdminToast.show(context, 'Progress reset.', type: AdminToastType.success);
    } else {
      AdminToast.show(context, 'Reset failed.', type: AdminToastType.error);
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Delete account permanently?',
      body: 'All user data including progress, gems, and notes will be deleted forever.',
      confirmLabel: 'Delete account',
    );
    if (!confirmed || !mounted) return;

    setState(() => _actionLoading = true);
    final ok = await _db.deleteLearner(widget.userId);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (ok) {
      AdminToast.show(context, 'Account deleted.', type: AdminToastType.success);
      Navigator.of(context).pop();
    } else {
      AdminToast.show(context, 'Delete failed.', type: AdminToastType.error);
    }
  }

  Future<void> _addGems() async {
    int? gemsToAdd;
    await showModalBottomSheet(
      context: context,
      backgroundColor: ac(context).bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final c = ac(context);
        final ctrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add gems', style: adminH2(c.textPrimary)),
              const SizedBox(height: 12),
              AdminInput(
                label: 'Gems to add',
                hint: '10',
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              AdminButton(
                label: 'Add gems',
                variant: AdminButtonVariant.accent,
                onTap: () {
                  gemsToAdd = int.tryParse(ctrl.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );

    if (gemsToAdd == null || gemsToAdd! <= 0 || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      final newGems = (_user?.gems ?? 0) + gemsToAdd!;
      final ok = await _db.updateLearner(widget.userId, {'gems': newGems});
      if (!mounted) return;
      if (ok) {
        await _loadUser();
        if (!mounted) return;
        AdminToast.show(
          context,
          '$gemsToAdd gems added.',
          type: AdminToastType.success,
        );
      } else {
        AdminToast.show(context, 'Failed to add gems.', type: AdminToastType.error);
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: const AdminTopBar(
          title: 'User',
          variant: AdminTopBarVariant.sub,
        ),
        body: AdminSkeletonLoader.listRows(count: 10),
      );
    }

    if (_hasError || _user == null) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: const AdminTopBar(
          title: 'User',
          variant: AdminTopBarVariant.sub,
        ),
        body: AdminErrorState(
          message: 'Could not load user.',
          onRetry: _loadUser,
        ),
      );
    }

    final user = _user!;
    final completedCount = _progress.where((p) => p.status == 'completed').length;

    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'User detail',
        variant: AdminTopBarVariant.sub,
        action: _actionLoading
            ? const SizedBox(
                width: 48,
                child: Center(
                    child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
              )
            : AdminTopBarIconButton(
                icon: LucideIcons.gem,
                onTap: _addGems,
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: bottomBuf),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Identity card
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              color: c.bgSurface,
              child: Row(
                children: [
                  AdminAvatar(
                    name: user.displayName,
                    size: 48,
                    isBanned: !user.isActive,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName
                                    : 'Anonymous',
                                style: adminH1(c.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AdminTag(
                              label: user.isActive ? 'Active' : 'Inactive',
                              variant: user.isActive
                                  ? AdminTagVariant.active
                                  : AdminTagVariant.inactive,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(user.email, style: adminBody(c.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          'Joined ${_relativeTime(user.createdAt)}',
                          style: adminMeta(c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const _Divider(),

            // Stats strip
            AdminStatStrip(
              stats: [
                AdminStat(label: 'XP', value: '${user.xp}'),
                AdminStat(label: 'Gems', value: '${user.gems}'),
                AdminStat(label: 'Streak', value: '${user.streakDays}d'),
                AdminStat(
                    label: 'Level', value: '${user.currentLevel}'),
              ],
            ),
            const _Divider(),

            // Progress
            AdminSectionHeader(title: 'Overview stats'),
            AdminRow(
              leading: Icon(LucideIcons.bookMarked, size: 14, color: c.textMuted),
              title: Text('Completed lessons', style: adminH3(c.textPrimary)),
              trailing: Text('$completedCount / ${_progress.length}', style: adminBody(c.textSecondary)),
            ),
            AdminRow(
              leading: Icon(LucideIcons.clock, size: 14, color: c.textMuted),
              title: Text('Total practice time', style: adminH3(c.textPrimary)),
              trailing: Text('${user.totalPracticeMinutes}m', style: adminBody(c.textSecondary)),
              isLast: true,
            ),
            const _Divider(),

            // Individual Lesson Progress
            AdminSectionHeader(title: 'Lesson progress detail'),
            if (_progress.isEmpty)
              const AdminEmptyState(icon: LucideIcons.book, title: 'No progress', body: 'This user hasn\'t started any lessons yet.'),
            ..._progress.asMap().entries.map((e) {
              final p = e.value;
              final bool isDone = p.status == 'completed';
              // Fallback for missing fields in model
              const int totalSigns = 10; // Expected average signs
              final double progressVal = isDone ? 1.0 : (p.signsCompleted.length / totalSigns);
              
              return AdminCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                radius: 0,
                showBorder: false,
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Lesson ${p.lessonId}', style: adminH3(c.textPrimary)),
                        Text('${(progressVal * 100).toInt()}%', style: adminMeta(isDone ? c.success : c.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AdminProgressBar(value: progressVal.clamp(0.0, 1.0)),
                  ],
                ),
              );
            }),
            const _Divider(),

            // Actions
            AdminSectionHeader(title: 'Actions'),
            AdminRow(
              leading: Icon(
                user.isActive ? LucideIcons.ban : LucideIcons.shieldCheck,
                size: 14,
                color: user.isActive ? c.error : c.success,
              ),
              title: Text(
                user.isActive ? 'Deactivate account' : 'Activate account',
                style: adminH3(user.isActive ? c.error : c.success),
              ),
              showChevron: true,
              onTap: _toggleStatus,
            ),
            AdminRow(
              leading: Icon(LucideIcons.gem, size: 14, color: c.accent),
              title: Text('Add gems', style: adminH3(c.textPrimary)),
              showChevron: true,
              onTap: _addGems,
            ),
            AdminRow(
              leading: Icon(LucideIcons.rotateCcw, size: 14, color: c.warning),
              title: Text('Reset progress', style: adminH3(c.warning)),
              showChevron: true,
              onTap: _resetProgress,
            ),
            AdminRow(
              leading: Icon(LucideIcons.trash2, size: 14, color: c.error),
              title: Text('Delete account', style: adminH3(c.error)),
              showChevron: true,
              isLast: true,
              onTap: _deleteUser,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: ac(context).bgBase,
    );
  }
}
