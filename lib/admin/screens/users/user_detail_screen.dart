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
  final Map<String, String> _lessonTitlesByKey = <String, String>{};
  final Map<String, int> _lessonSignCountsByKey = <String, int>{};
  final Map<String, String> _categoryNamesById = <String, String>{};
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
      final displayData = await _resolveProgressDisplayData(progress);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
        return;
      }

      progress.sort((a, b) {
        final aTimestamp =
            a.completedAt ??
            a.startedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTimestamp =
            b.completedAt ??
            b.startedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTimestamp.compareTo(aTimestamp);
      });

      setState(() {
        _user = user;
        _progress = progress;
        _lessonTitlesByKey
          ..clear()
          ..addAll(displayData.lessonTitlesByKey);
        _lessonSignCountsByKey
          ..clear()
          ..addAll(displayData.lessonSignCountsByKey);
        _categoryNamesById
          ..clear()
          ..addAll(displayData.categoryNamesById);
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

  Future<_ProgressDisplayData> _resolveProgressDisplayData(
    List<LessonProgress> progress,
  ) async {
    final lessonTitlesByKey = <String, String>{};
    final lessonSignCountsByKey = <String, int>{};
    final categoryNamesById = <String, String>{};

    final categoryIds = <String>{};
    for (final p in progress) {
      if (p.categoryId.trim().isNotEmpty) {
        categoryIds.add(p.categoryId.trim());
      }
    }

    for (final categoryId in categoryIds) {
      try {
        final categoryDoc = await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .get();
        if (categoryDoc.exists) {
          final data = categoryDoc.data() ?? <String, dynamic>{};
          final name = (data['name'] ?? categoryId).toString().trim();
          if (name.isNotEmpty) {
            categoryNamesById[categoryId] = name;
          }
        }
      } catch (_) {}
    }

    for (final p in progress) {
      final categoryId = p.categoryId.trim();
      final lessonId = p.lessonId.trim();
      if (categoryId.isEmpty || lessonId.isEmpty) {
        continue;
      }

      final lessonKey = '$categoryId/$lessonId';
      if (lessonTitlesByKey.containsKey(lessonKey)) {
        continue;
      }

      try {
        final lessonDoc = await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .collection('lessons')
            .doc(lessonId)
            .get();
        if (lessonDoc.exists) {
          final lessonData = lessonDoc.data() ?? <String, dynamic>{};
          final lessonTitle = (lessonData['title'] ?? lessonId)
              .toString()
              .trim();
          if (lessonTitle.isNotEmpty) {
            lessonTitlesByKey[lessonKey] = lessonTitle;
          }

          final explicitTotalSigns = (lessonData['totalSigns'] as num?)
              ?.toInt();
          if (explicitTotalSigns != null && explicitTotalSigns > 0) {
            lessonSignCountsByKey[lessonKey] = explicitTotalSigns;
          }
        }
      } catch (_) {}
    }

    return _ProgressDisplayData(
      lessonTitlesByKey: lessonTitlesByKey,
      lessonSignCountsByKey: lessonSignCountsByKey,
      categoryNamesById: categoryNamesById,
    );
  }

  String _lessonKey(LessonProgress p) =>
      '${p.categoryId.trim()}/${p.lessonId.trim()}';

  String _normalizeStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'completed') return 'Completed';
    if (normalized == 'in_progress' || normalized == 'in-progress') {
      return 'In progress';
    }
    return 'Not started';
  }

  String _formatDurationSeconds(int seconds) {
    if (seconds <= 0) return '0m';
    final totalMinutes = seconds ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Future<void> _toggleStatus() async {
    if (_user == null || _actionLoading) return;
    final newActive = !_user!.isActive;
    final confirmed = await AdminConfirmModal.show(
      context,
      title: '${newActive ? 'Enable' : 'Disable'} learner login?',
      body: newActive
          ? 'This learner will regain access to the app.'
          : 'This learner will be blocked from using the app, but their profile will stay visible here.',
      confirmLabel: newActive ? 'Enable login' : 'Disable login',
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
        'Learner login ${newActive ? 'enabled' : 'disabled'}.',
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
      body:
          'This will delete all lesson completions, XP, gems, and streaks. This cannot be undone.',
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
        AdminToast.show(
          context,
          'Failed to add gems.',
          type: AdminToastType.error,
        );
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
        appBar: AdminTopBar(
          title: 'User',
          variant: AdminTopBarVariant.sub,
          adminName: widget.admin.displayName,
          adminEmail: widget.admin.email,
        ),
        body: AdminSkeletonLoader.listRows(count: 10),
      );
    }

    if (_hasError || _user == null) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: AdminTopBar(
          title: 'User',
          variant: AdminTopBarVariant.sub,
          adminName: widget.admin.displayName,
          adminEmail: widget.admin.email,
        ),
        body: AdminErrorState(
          message: 'Could not load user.',
          onRetry: _loadUser,
        ),
      );
    }

    final user = _user!;
    final completedCount = _progress
        .where((p) => p.status == 'completed')
        .length;

    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'User detail',
        variant: AdminTopBarVariant.sub,
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
            : AdminTopBarIconButton(icon: LucideIcons.gem, onTap: _addGems),
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
                AdminStat(label: 'Level', value: '${user.currentLevel}'),
              ],
            ),
            const _Divider(),

            // Progress
            AdminSectionHeader(title: 'Overview stats'),
            AdminRow(
              leading: Icon(
                LucideIcons.bookMarked,
                size: 14,
                color: c.textMuted,
              ),
              title: Text('Completed lessons', style: adminH3(c.textPrimary)),
              trailing: Text(
                '$completedCount / ${_progress.length}',
                style: adminBody(c.textSecondary),
              ),
            ),
            AdminRow(
              leading: Icon(LucideIcons.clock, size: 14, color: c.textMuted),
              title: Text('Total practice time', style: adminH3(c.textPrimary)),
              trailing: Text(
                '${user.totalPracticeMinutes}m',
                style: adminBody(c.textSecondary),
              ),
              isLast: true,
            ),
            const _Divider(),

            // Individual Lesson Progress
            AdminSectionHeader(title: 'Lesson progress detail'),
            if (_progress.isEmpty)
              const AdminEmptyState(
                icon: LucideIcons.book,
                title: 'No lesson activity yet',
                body:
                    'Progress cards will appear here once this learner starts lessons.',
              ),
            ..._progress.asMap().entries.map((e) {
              final p = e.value;
              final isDone = p.status == 'completed';
              final lessonKey = _lessonKey(p);
              final lessonTitle =
                  _lessonTitlesByKey[lessonKey] ?? 'Lesson ${p.lessonId}';
              final categoryTitle =
                  _categoryNamesById[p.categoryId] ?? p.categoryId;
              final trackedTotalSigns =
                  _lessonSignCountsByKey[lessonKey] ??
                  (p.signsCompleted.length + p.signsSkipped.length);
              final completedSigns = p.signsCompleted.length;

              double progressVal;
              if (isDone) {
                progressVal = 1.0;
              } else if (trackedTotalSigns > 0) {
                progressVal = completedSigns / trackedTotalSigns;
              } else if (p.status == 'in_progress') {
                progressVal = 0.1;
              } else {
                progressVal = 0.0;
              }

              return AdminCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                radius: 0,
                showBorder: false,
                showShadow: false,
                color: c.bgSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lessonTitle,
                                style: adminH3(c.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                categoryTitle,
                                style: adminMeta(c.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AdminTag(
                          label: _normalizeStatus(p.status).toUpperCase(),
                          variant: isDone
                              ? AdminTagVariant.active
                              : (p.status == 'in_progress'
                                    ? AdminTagVariant.pending
                                    : AdminTagVariant.draft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AdminProgressBar(value: progressVal.clamp(0.0, 1.0)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          '${(progressVal * 100).toInt()}% complete',
                          style: adminMeta(isDone ? c.success : c.textMuted),
                        ),
                        Text(
                          'Signs: $completedSigns/${trackedTotalSigns > 0 ? trackedTotalSigns : '-'}',
                          style: adminMeta(c.textSecondary),
                        ),
                        Text(
                          'Accuracy: ${(p.accuracy * 100).toStringAsFixed(0)}%',
                          style: adminMeta(c.textSecondary),
                        ),
                        Text(
                          'Time: ${_formatDurationSeconds(p.timeSpentSeconds)}',
                          style: adminMeta(c.textSecondary),
                        ),
                        Text(
                          'Attempts: ${p.attemptsCount}',
                          style: adminMeta(c.textSecondary),
                        ),
                      ],
                    ),
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
                user.isActive ? 'Disable login' : 'Enable login',
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
              isLast: true,
              onTap: _resetProgress,
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
    return Container(height: 8, color: ac(context).bgBase);
  }
}

class _ProgressDisplayData {
  final Map<String, String> lessonTitlesByKey;
  final Map<String, int> lessonSignCountsByKey;
  final Map<String, String> categoryNamesById;

  const _ProgressDisplayData({
    required this.lessonTitlesByKey,
    required this.lessonSignCountsByKey,
    required this.categoryNamesById,
  });
}
