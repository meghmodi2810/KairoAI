import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/services/admin_auth_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';
import 'package:kairo_ai/admin/widgets/a_inputs.dart';
import 'package:kairo_ai/admin/widgets/a_overlays.dart';

class AdminSettingsScreen extends StatefulWidget {
  final AdminModel admin;
  final VoidCallback onMenuTap;
  final int initialTabIndex;

  const AdminSettingsScreen({
    super.key,
    required this.admin,
    required this.onMenuTap,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 4,
      vsync: this,
      initialIndex: (widget.initialTabIndex < 4) ? widget.initialTabIndex : 0,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'Settings',
        onMenuTap: widget.onMenuTap,
        adminName: widget.admin.displayName,
        adminEmail: widget.admin.email,
      ),
      body: Column(
        children: [
          Container(
            color: c.bgSurface,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: c.isDark ? c.accentBright : c.accent,
              unselectedLabelColor: c.textMuted,
              indicatorColor: c.isDark ? c.accentBright : c.accent,
              indicatorWeight: 2,
              dividerHeight: 1,
              dividerColor: c.border,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'LEVELS'),
                Tab(text: 'ADMINS'),
                Tab(text: 'ACTIVITY'),
                Tab(text: 'PROFILE'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _LevelConfigTab(admin: widget.admin),
                _AdminManagementTab(admin: widget.admin),
                _AuditLogTab(),
                _AccountTab(admin: widget.admin),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelConfigTab extends StatefulWidget {
  final AdminModel admin;
  const _LevelConfigTab({required this.admin});

  @override
  State<_LevelConfigTab> createState() => _LevelConfigTabState();
}

class _LevelConfigTabState extends State<_LevelConfigTab> {
  final _db = AdminDatabaseService();
  final _thresholdCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _recalculating = false;
  int? _lastRecalculatedUsers;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    final config = await _db.getLevelConfig();
    if (!mounted) return;
    setState(() {
      _thresholdCtrl.text = config.xpThresholds.join(', ');
      _loading = false;
    });
  }

  List<int>? _parseThresholds() {
    final raw = _thresholdCtrl.text
        .split(RegExp(r'[,\s]+'))
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList(growable: false);

    if (raw.isEmpty) return null;

    final values = <int>[];
    for (final token in raw) {
      final parsed = int.tryParse(token);
      if (parsed == null) {
        return null;
      }
      values.add(parsed);
    }
    return LevelConfigModel.normalizeThresholds(values);
  }

  Future<void> _saveConfig() async {
    final thresholds = _parseThresholds();
    if (thresholds == null || thresholds.length < 2) {
      AdminToast.show(
        context,
        'Provide at least 2 valid XP thresholds.',
        type: AdminToastType.error,
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await _db.updateLevelConfig(
      LevelConfigModel(xpThresholds: thresholds),
      updatedBy: widget.admin.uid,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    AdminToast.show(
      context,
      ok ? 'Level configuration updated.' : 'Failed to save level configuration.',
      type: ok ? AdminToastType.success : AdminToastType.error,
    );

    if (ok) {
      await _loadConfig();
    }
  }

  Future<void> _recalculateLevels() async {
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Recalculate all learner levels?',
      body: 'This applies the current XP thresholds to every learner account.',
      confirmLabel: 'Recalculate now',
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() => _recalculating = true);
    final updatedCount = await _db.recalculateAllLearnerLevels();
    if (!mounted) return;
    setState(() {
      _recalculating = false;
      _lastRecalculatedUsers = updatedCount;
    });

    AdminToast.show(
      context,
      'Recalculated levels for $updatedCount learner(s).',
      type: AdminToastType.success,
    );
  }

  List<int> _previewThresholds() {
    final parsed = _parseThresholds();
    if (parsed == null || parsed.isEmpty) {
      return LevelConfigModel.defaultThresholds;
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    if (_loading) return AdminSkeletonLoader.listRows(count: 5);

    final previewThresholds = _previewThresholds();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(screenPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('XP Level Configuration', style: adminH2(c.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Define level thresholds with XP breakpoints. Level is derived from XP; it is never manually assigned.',
                  style: adminBodySm(c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AdminInput(
            label: 'XP thresholds',
            hint: '0, 120, 280, 520, 860, 1300',
            helperText: 'Comma or space separated values. First level starts at 0 XP.',
            controller: _thresholdCtrl,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: previewThresholds
                  .asMap()
                  .entries
                  .map((entry) {
                    final i = entry.key;
                    final threshold = entry.value;
                    return AdminRow(
                      isLast: i == previewThresholds.length - 1,
                      title: Text('Level ${i + 1}', style: adminH3(c.textPrimary)),
                      subtitle: Text('Starts at $threshold XP', style: adminMeta(c.textSecondary)),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          if (_lastRecalculatedUsers != null) ...[
            const SizedBox(height: 10),
            Text(
              'Last recalculation updated $_lastRecalculatedUsers learner(s).',
              style: adminBodySm(c.textMuted),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AdminButton(
                  label: 'Save thresholds',
                  variant: AdminButtonVariant.accent,
                  isLoading: _saving,
                  onTap: _saving ? null : _saveConfig,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminButton(
                  label: 'Recalculate levels',
                  variant: AdminButtonVariant.secondary,
                  isLoading: _recalculating,
                  onTap: _recalculating ? null : _recalculateLevels,
                ),
              ),
            ],
          ),
          const SizedBox(height: bottomBuf),
        ],
      ),
    );
  }
}

class _AdminManagementTab extends StatefulWidget {
  final AdminModel admin;
  const _AdminManagementTab({required this.admin});

  @override
  State<_AdminManagementTab> createState() => _AdminManagementTabState();
}

class _AdminManagementTabState extends State<_AdminManagementTab> {
  final _db = AdminDatabaseService();
  String? _busyAdminId;

  @override
  Future<void> _toggleAdminStatus(AdminModel target, bool toActive) async {
    final title = toActive ? 'Reactivate admin?' : 'Deactivate admin?';
    final body = toActive
        ? 'This account will regain full admin access.'
        : 'This account will lose admin access until reactivated.';

    final confirmed = await AdminConfirmModal.show(
      context,
      title: title,
      body: body,
      confirmLabel: toActive ? 'Reactivate' : 'Deactivate',
      isDestructive: !toActive,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyAdminId = target.id);
    final result = await _db.setAdminActiveStatus(
      adminId: target.id,
      isActive: toActive,
      actingAdminId: widget.admin.id,
    );
    if (!mounted) return;
    setState(() => _busyAdminId = null);

    AdminToast.show(
      context,
      result.message,
      type: result.success ? AdminToastType.success : AdminToastType.error,
    );
  }

  Future<void> _removeAdmin(AdminModel target) async {
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Remove admin access?',
      body: 'This will fully remove admin permissions for ${target.email}.',
      confirmLabel: 'Remove admin',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyAdminId = target.id);
    final result = await _db.removeAdminAccess(
      adminId: target.id,
      actingAdminId: widget.admin.id,
    );
    if (!mounted) return;
    setState(() => _busyAdminId = null);

    AdminToast.show(
      context,
      result.message,
      type: result.success ? AdminToastType.success : AdminToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);

    return StreamBuilder<List<AdminModel>>(
      stream: _db.adminsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AdminSkeletonLoader.listRows(count: 6);
        }
        if (snapshot.hasError) {
          return AdminErrorState(onRetry: () => setState(() {}));
        }

        final admins = snapshot.data ?? <AdminModel>[];
        final activeCount = admins.where((admin) => admin.isActive).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Single Admin Tier', style: adminH2(c.textPrimary)),
                    const SizedBox(height: 6),
                    Text(
                      'Every active admin has full governance access. Last active admin is protected from removal/deactivation.',
                      style: adminBodySm(c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AdminSectionHeader(
                title: 'Active admins: $activeCount · Total: ${admins.length}',
              ),
              if (admins.isEmpty)
                const AdminEmptyState(
                  icon: LucideIcons.shield,
                  title: 'No admin accounts found',
                  body: 'Add an admin by email to initialize governance.',
                )
              else
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: admins.asMap().entries.map((entry) {
                      final index = entry.key;
                      final admin = entry.value;
                      final isSelf = admin.id == widget.admin.id;
                      final isBusy = _busyAdminId == admin.id;

                      return AdminRow(
                        isLast: index == admins.length - 1,
                        leading: AdminAvatar(name: admin.displayName),
                        title: Text(
                          admin.displayName.isNotEmpty
                              ? admin.displayName
                              : admin.email,
                          style: adminH3(c.textPrimary),
                        ),
                        subtitle: Text(
                          '${admin.email}${isSelf ? ' · You' : ''}',
                          style: adminMeta(c.textSecondary),
                        ),
                        trailing: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : PopupMenuButton<String>(
                                icon: Icon(LucideIcons.moreVertical, size: 16, color: c.textMuted),
                                onSelected: (value) {
                                  if (value == 'activate') {
                                    _toggleAdminStatus(admin, true);
                                  } else if (value == 'deactivate') {
                                    _toggleAdminStatus(admin, false);
                                  } else if (value == 'remove') {
                                    _removeAdmin(admin);
                                  }
                                },
                                itemBuilder: (_) => <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: admin.isActive ? 'deactivate' : 'activate',
                                    child: Text(admin.isActive ? 'Deactivate' : 'Reactivate'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'remove',
                                    child: Text('Remove admin access'),
                                  ),
                                ],
                              ),
                        showChevron: false,
                      );
                    }).toList(growable: false),
                  ),
                ),
              const SizedBox(height: bottomBuf),
            ],
          ),
        );
      },
    );
  }
}

class _AuditLogTab extends StatefulWidget {
  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  final _db = AdminDatabaseService();

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return StreamBuilder<List<AuditLogModel>>(
      stream: _db.auditLogsStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AdminSkeletonLoader.listRows(count: 10);
        }
        if (snapshot.hasError) return AdminErrorState(onRetry: () => setState(() {}));
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const AdminEmptyState(
            icon: LucideIcons.history,
            title: 'No activity found',
            body: 'Platform logs will appear here as they occur.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: logs.length,
          itemBuilder: (context, i) {
            final log = logs[i];
            return AdminRow(
              isLast: i == logs.length - 1,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: c.bgSurface2, borderRadius: BorderRadius.circular(6)),
                child: Center(child: Icon(LucideIcons.scrollText, size: 14, color: c.textMuted)),
              ),
              title: Text(log.details, style: adminH3(c.textPrimary)),
              subtitle: Text('${log.adminEmail} · ${_timeAgo(log.timestamp)}', style: adminMeta(c.textSecondary)),
            );
          },
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AccountTab extends StatefulWidget {
  final AdminModel admin;
  const _AccountTab({required this.admin});

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  final _auth = AdminAuthService();
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmNewPw = TextEditingController();
  String? _currentPwError;
  String? _newPwError;
  String? _confirmPwError;
  bool _changingPw = false;

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _confirmNewPw.dispose();
    super.dispose();
  }

  String? _passwordConstraintError(String value) {
    final password = value.trim();
    if (password.length < 8) {
      return 'Must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Include at least 1 uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Include at least 1 lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Include at least 1 number.';
    }
    return null;
  }

  Future<void> _updatePassword() async {
    final currentPassword = _currentPw.text;
    final newPassword = _newPw.text;
    final confirmPassword = _confirmNewPw.text;

    final currentErr = currentPassword.isEmpty ? 'Current password is required.' : null;
    String? newErr = newPassword.isEmpty ? 'New password is required.' : _passwordConstraintError(newPassword);
    String? confirmErr;

    if (confirmPassword.isEmpty) {
      confirmErr = 'Please confirm the new password.';
    } else if (newPassword != confirmPassword) {
      confirmErr = 'New password and confirmation must match.';
    }

    if (currentErr == null && newErr == null && currentPassword.trim() == newPassword.trim()) {
      newErr = 'New password must be different from current password.';
    }

    setState(() {
      _currentPwError = currentErr;
      _newPwError = newErr;
      _confirmPwError = confirmErr;
    });

    if (currentErr != null || newErr != null || confirmErr != null) {
      AdminToast.show(context, 'Please resolve password validation errors.', type: AdminToastType.error);
      return;
    }

    setState(() => _changingPw = true);
    final ok = await _auth.changePassword(currentPassword.trim(), newPassword.trim());
    if (!mounted) return;
    setState(() => _changingPw = false);
    if (ok) {
      _currentPw.clear();
      _newPw.clear();
      _confirmNewPw.clear();
      _currentPwError = null;
      _newPwError = null;
      _confirmPwError = null;
      AdminToast.show(context, 'Account security updated');
    } else {
      AdminToast.show(context, 'Verification failed', type: AdminToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(screenPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AdminAvatar(name: widget.admin.displayName, size: 60),
                const SizedBox(height: 16),
                Text(widget.admin.displayName, style: adminH2(c.textPrimary)),
                const SizedBox(height: 4),
                Text(widget.admin.email, style: adminBody(c.textMuted)),
                const SizedBox(height: 12),
                AdminTag(label: 'SYSTEM ADMINISTRATOR', variant: AdminTagVariant.active),
              ],
            ),
          ),
          const SizedBox(height: 20),

          AdminSectionHeader(title: 'Security refresh'),
          AdminCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AdminInput(
                  label: 'Current password',
                  controller: _currentPw,
                  obscureText: true,
                  errorText: _currentPwError,
                  onChanged: (_) {
                    if (_currentPwError != null) {
                      setState(() => _currentPwError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                AdminInput(
                  label: 'New password',
                  controller: _newPw,
                  obscureText: true,
                  errorText: _newPwError,
                  helperText: 'At least 8 characters with uppercase, lowercase, and number.',
                  onChanged: (_) {
                    if (_newPwError != null || _confirmPwError != null) {
                      setState(() {
                        _newPwError = null;
                        _confirmPwError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                AdminInput(
                  label: 'Confirm new password',
                  controller: _confirmNewPw,
                  obscureText: true,
                  errorText: _confirmPwError,
                  onChanged: (_) {
                    if (_confirmPwError != null) {
                      setState(() => _confirmPwError = null);
                    }
                  },
                ),
                const SizedBox(height: 20),
                AdminButton(
                  label: 'Apply changes',
                  variant: AdminButtonVariant.accent,
                  onTap: _changingPw ? null : _updatePassword,
                  isLoading: _changingPw,
                ),
              ],
            ),
          ),
          const SizedBox(height: bottomBuf),
        ],
      ),
    );
  }
}
