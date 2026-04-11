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
import 'package:kairo_ai/main.dart';

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
      length: 3,
      vsync: this,
      initialIndex: (widget.initialTabIndex < 3) ? widget.initialTabIndex : 0,
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
                Tab(text: 'MAINTENANCE'),
                Tab(text: 'ACTIVITY'),
                Tab(text: 'PROFILE'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _MaintenanceTab(admin: widget.admin),
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

class _MaintenanceTab extends StatefulWidget {
  final AdminModel admin;
  const _MaintenanceTab({required this.admin});

  @override
  State<_MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<_MaintenanceTab> {
  final _db = AdminDatabaseService();
  final _msgCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final mode = await _db.getMaintenanceMode();
      if (!mounted) return;
      setState(() {
        _enabled = mode?.isEnabled ?? false;
        _msgCtrl.text = mode?.message ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    final newEnabled = !_enabled;
    if (newEnabled) {
      final confirmed = await AdminConfirmModal.show(
        context,
        title: 'Activate maintenance?',
        body: 'Learners will see a lockout screen. This is typically used for critical platform updates.',
        confirmLabel: 'Activate now',
        isDestructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _saving = true);
    final mode = MaintenanceModeModel(
      isEnabled: newEnabled,
      message: _msgCtrl.text.trim().isNotEmpty
          ? _msgCtrl.text.trim()
          : 'KairoAI is currently undergoing scheduled maintenance.',
      enabledAt: newEnabled ? DateTime.now() : null,
    );
    final ok = await _db.updateMaintenanceMode(mode);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _enabled = newEnabled;
    });
    AdminToast.show(
      context,
      ok ? (newEnabled ? 'Maintenance active' : 'Platform live') : 'Platform sync failed',
      type: ok ? (newEnabled ? AdminToastType.warning : AdminToastType.success) : AdminToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    if (_loading) return AdminSkeletonLoader.listRows(count: 3);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(screenPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _enabled ? c.error : c.success,
                    border: Border.all(color: c.bgSurface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (_enabled ? c.error : c.success).withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _enabled ? 'Maintenance active' : 'System operational',
                        style: adminH3(c.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _enabled ? 'Access is restricted for all learners.' : 'All services are functioning normally.',
                        style: adminBodySm(c.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AdminSectionHeader(title: 'Lockout notification'),
          AdminInput(
            label: 'Lockout notification',
            hint: 'Message for learners...',
            controller: _msgCtrl,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          AdminButton(
            label: _enabled ? 'Restore platform access' : 'Restrict access now',
            variant: _enabled ? AdminButtonVariant.secondary : AdminButtonVariant.destructive,
            onTap: _saving ? null : _toggle,
            isLoading: _saving,
          ),
        ],
      ),
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
  bool _changingPw = false;

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_currentPw.text.isEmpty || _newPw.text.isEmpty) {
      AdminToast.show(context, 'Verify all fields', type: AdminToastType.error);
      return;
    }
    setState(() => _changingPw = true);
    final ok = await _auth.changePassword(_currentPw.text.trim(), _newPw.text.trim());
    if (!mounted) return;
    setState(() => _changingPw = false);
    if (ok) {
      _currentPw.clear();
      _newPw.clear();
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
          AdminSectionHeader(title: 'Display theme'),
          AdminCard(
            padding: const EdgeInsets.all(0),
            child: AdminRow(
              isLast: true,
              leading: Icon(
                MyApp.themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                size: 14,
                color: c.accent,
              ),
              title: Text('Dark appearance', style: adminH3(c.textPrimary)),
              subtitle: Text('Switch between light and dark modes', style: adminMeta(c.textSecondary)),
              trailing: Switch.adaptive(
                value: MyApp.themeProvider.isDarkMode,
                activeTrackColor: c.accent,
                onChanged: (v) {
                   MyApp.themeProvider.toggleTheme();
                   setState(() {}); // Rebuild local toggle
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          AdminSectionHeader(title: 'Security refresh'),
          AdminCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AdminInput(label: 'Current password', controller: _currentPw, obscureText: true),
                const SizedBox(height: 16),
                AdminInput(label: 'New security key', controller: _newPw, obscureText: true),
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
