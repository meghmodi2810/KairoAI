import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../widgets/admin_widgets.dart';

class SettingsPage extends StatefulWidget {
  final AdminModel admin;

  const SettingsPage({super.key, required this.admin});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  
  int _selectedTab = 0;
  bool _isLoadingMaintenance = true;
  MaintenanceModeModel? _maintenanceMode;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceMode();
  }

  Future<void> _loadMaintenanceMode() async {
    try {
      final mode = await _dbService.getMaintenanceMode();
      if (mounted) setState(() { _maintenanceMode = mode; _isLoadingMaintenance = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMaintenance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
          SizedBox(height: 2),
          Text('System configuration', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Maintenance', 'Audit Log', 'Account'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final isSelected = _selectedTab == e.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(e.value),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedTab = e.key),
                backgroundColor: AdminTheme.cardBg,
                selectedColor: AdminTheme.accentYellow,
                labelStyle: TextStyle(fontSize: 12, color: isSelected ? AdminTheme.primaryDark : AdminTheme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                checkmarkColor: AdminTheme.primaryDark,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildMaintenanceTab();
      case 1:
        return _buildAuditLogTab();
      case 2:
        return _buildAccountTab();
      default:
        return _buildMaintenanceTab();
    }
  }

  Widget _buildMaintenanceTab() {
    if (_isLoadingMaintenance) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Maintenance Mode Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_maintenanceMode?.isEnabled ?? false) ? AdminTheme.warning.withOpacity(0.2) : AdminTheme.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        (_maintenanceMode?.isEnabled ?? false) ? Icons.build : Icons.check_circle,
                        color: (_maintenanceMode?.isEnabled ?? false) ? AdminTheme.warning : AdminTheme.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Maintenance Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                          Text(
                            (_maintenanceMode?.isEnabled ?? false) ? 'App is in maintenance' : 'App is live',
                            style: TextStyle(fontSize: 11, color: (_maintenanceMode?.isEnabled ?? false) ? AdminTheme.warning : AdminTheme.success),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _maintenanceMode?.isEnabled ?? false,
                      onChanged: (value) => _toggleMaintenanceMode(value),
                      activeColor: AdminTheme.warning,
                    ),
                  ],
                ),
                if (_maintenanceMode?.isEnabled ?? false) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AdminTheme.warning, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_maintenanceMode?.message ?? 'Under maintenance', style: const TextStyle(fontSize: 11, color: AdminTheme.warning)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Database Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AdminTheme.info.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.storage, color: AdminTheme.info, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Database Tools', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildToolButton('Seed Data', Icons.add_box, AdminTheme.success, () => _showSeedConfirm()),
                    _buildToolButton('Clear Cache', Icons.cached, AdminTheme.info, () {}),
                    _buildToolButton('Backup', Icons.backup, AdminTheme.accentPink, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogTab() {
    return StreamBuilder<List<AuditLogModel>>(
      stream: _dbService.auditLogsStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow)));
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: AdminTheme.textSecondary),
                SizedBox(height: 12),
                Text('No Audit Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) => _buildLogCard(logs[index]),
        );
      },
    );
  }

  Widget _buildLogCard(AuditLogModel log) {
    final actionColors = {
      'create': AdminTheme.success,
      'update': AdminTheme.info,
      'delete': AdminTheme.error,
    };
    final color = actionColors[log.action] ?? AdminTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
            child: Icon(_getActionIcon(log.action), color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log.adminName} ${log.action}d ${log.entityType}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AdminTheme.textPrimary)),
                Text(_formatDateTime(log.timestamp), style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AdminTheme.primaryBlue,
                  child: Text(
                    widget.admin.displayName.isNotEmpty ? widget.admin.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.admin.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(widget.admin.email, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AdminTheme.accentYellow.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(widget.admin.role.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.accentYellow)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Account Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                const SizedBox(height: 12),
                _buildInfoRow('UID', widget.admin.uid),
                _buildInfoRow('Role', widget.admin.role.replaceAll('_', ' ')),
                _buildInfoRow('Created', widget.admin.createdAt != null ? _formatDate(widget.admin.createdAt!) : 'N/A'),
                _buildInfoRow('Last Login', widget.admin.lastLoginAt != null ? _formatDateTime(widget.admin.lastLoginAt!) : 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Permissions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Permissions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.admin.permissions.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AdminTheme.success.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(p.replaceAll('_', ' '), style: const TextStyle(fontSize: 10, color: AdminTheme.success)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AdminTheme.textPrimary))),
        ],
      ),
    );
  }

  Future<void> _toggleMaintenanceMode(bool enable) async {
    if (enable) {
      final controller = TextEditingController(text: 'App is under maintenance. Please try again later.');
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AdminTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Enable Maintenance?', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Users will see maintenance message', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.warning),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        final mode = MaintenanceModeModel(
          isEnabled: true,
          message: controller.text,
          enabledBy: widget.admin.uid,
          enabledAt: DateTime.now(),
        );
        await _dbService.setMaintenanceMode(mode);
        _loadMaintenanceMode();
      }
    } else {
      final mode = MaintenanceModeModel(isEnabled: false);
      await _dbService.setMaintenanceMode(mode);
      _loadMaintenanceMode();
    }
  }

  Future<void> _showSeedConfirm() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Seed Database?', style: TextStyle(color: Colors.white)),
        content: const Text('This feature is not yet implemented.', style: TextStyle(color: AdminTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('OK')),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _formatDateTime(DateTime date) => '${_formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
