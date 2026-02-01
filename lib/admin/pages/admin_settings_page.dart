import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';

/// Admin Settings Page - Configure app settings, maintenance, and view logs
class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> with SingleTickerProviderStateMixin {
  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
  static const Color cardBg = Color(0xFF262F4D);
  static const Color inputBg = Color(0xFF252A5E);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentBlue = Color(0xFF5CB6F9);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE57373);
  static const Color accentOrange = Color(0xFFFF9800);

  final AdminDatabaseService _dbService = AdminDatabaseService();
  late TabController _tabController;

  // Settings state
  bool _maintenanceEnabled = false;
  final TextEditingController _maintenanceMessageController = TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();
  bool _forceUpdate = false;
  bool _allowGuestMode = true;
  int _maxDailyPractice = 100;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _maintenanceMessageController.dispose();
    _appVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkBlue,
      child: Column(
        children: [
          // Tab bar
          Container(
            color: cardBg,
            child: TabBar(
              controller: _tabController,
              indicatorColor: accentYellow,
              labelColor: accentYellow,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'General', icon: Icon(Icons.settings, size: 20)),
                Tab(text: 'Maintenance', icon: Icon(Icons.build, size: 20)),
                Tab(text: 'Audit Logs', icon: Icon(Icons.history, size: 20)),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralSettingsTab(),
                _buildMaintenanceTab(),
                _buildAuditLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // App version
          _buildSettingsCard('App Version', [
            _buildInputField(_appVersionController, 'Current Version', Icons.info),
            const SizedBox(height: 12),
            _buildToggleRow('Force Update', _forceUpdate, (v) {
              setState(() => _forceUpdate = v);
            }),
          ]),
          const SizedBox(height: 16),
          // User settings
          _buildSettingsCard('User Settings', [
            _buildToggleRow('Allow Guest Mode', _allowGuestMode, (v) {
              setState(() => _allowGuestMode = v);
            }),
            const SizedBox(height: 12),
            _buildSliderControl(
              'Max Daily Practice Sessions',
              _maxDailyPractice,
              10,
              200,
              (v) => setState(() => _maxDailyPractice = v.round()),
            ),
          ]),
          const SizedBox(height: 24),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maintenance Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _maintenanceEnabled ? accentOrange.withOpacity(0.1) : accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _maintenanceEnabled ? accentOrange.withOpacity(0.3) : accentGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _maintenanceEnabled ? Icons.warning : Icons.check_circle,
                  color: _maintenanceEnabled ? accentOrange : accentGreen,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _maintenanceEnabled ? 'Maintenance Active' : 'App Online',
                        style: TextStyle(
                          color: _maintenanceEnabled ? accentOrange : accentGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _maintenanceEnabled
                            ? 'Users cannot access the app'
                            : 'App is functioning normally',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _maintenanceEnabled,
                  onChanged: (value) => setState(() => _maintenanceEnabled = value),
                  activeColor: accentOrange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Message card
          _buildSettingsCard('Maintenance Message', [
            TextField(
              controller: _maintenanceMessageController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter message to display to users...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveMaintenanceSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: _maintenanceEnabled ? accentOrange : accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_maintenanceEnabled ? 'Enable Maintenance' : 'Update Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text(
                'Audit Logs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh, color: accentBlue),
                label: const Text('Refresh', style: TextStyle(color: accentBlue)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AuditLogModel>>(
            stream: _dbService.auditLogsStream(limit: 50),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No audit logs found',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return _buildLogItem(snapshot.data![index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(AuditLogModel log) {
    final color = _getActionColor(log.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getActionIcon(log.action), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.action} ${log.entityType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${log.adminName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (log.entityId?.isNotEmpty == true)
                  Text(
                    'ID: ${log.entityId}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(log.timestamp),
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: accentGreen,
        ),
      ],
    );
  }

  Widget _buildSliderControl(String label, int value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            Text(
              '$value',
              style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          activeColor: accentYellow,
          inactiveColor: inputBg,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return accentGreen;
      case 'update':
        return accentBlue;
      case 'delete':
        return accentRed;
      default:
        return accentYellow;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _saveSettings() {
    _showSnackBar('Settings saved successfully', accentGreen);
  }

  void _saveMaintenanceSettings() {
    _showSnackBar(
      _maintenanceEnabled ? 'Maintenance mode enabled' : 'Settings updated',
      _maintenanceEnabled ? accentOrange : accentGreen,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
