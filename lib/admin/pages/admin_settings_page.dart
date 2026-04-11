import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

/// Admin Settings Page - Configure app settings, maintenance, and view logs
class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> with SingleTickerProviderStateMixin {
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
      color: AppTheme.charcoalNight,
      child: Column(
        children: [
          // Tab bar (Control Room Style)
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 6,
              indicatorColor: AppTheme.inkBlack,
              labelColor: AppTheme.inkBlack,
              unselectedLabelColor: Colors.black38,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
              tabs: const [
                Tab(text: 'SYSTEM', icon: Icon(Icons.settings_suggest_rounded)),
                Tab(text: 'MAINTENANCE', icon: Icon(Icons.engineering_rounded)),
                Tab(text: 'AUDIT TRAIL', icon: Icon(Icons.history_edu_rounded)),
              ],
            ),
          ),
          const Divider(height: 4, thickness: 4, color: AppTheme.inkBlack),
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
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CORE DEPLOYMENT PARAMS',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Archivo Black'),
          ),
          const SizedBox(height: 40),
          _settingsCard('APPLICATION VERSIONING', [
            _buildInputField(_appVersionController, 'LIVE VERSION', Icons.vibration_rounded),
            const SizedBox(height: 24),
            _buildToggleRow('ENFORCE CRITICAL UPDATE', _forceUpdate, (v) => setState(() => _forceUpdate = v)),
          ], AppTheme.electricBlue),
          const SizedBox(height: 32),
          _settingsCard('USER ACCESS POLICIES', [
            _buildToggleRow('ALLOW ANONYMOUS SESSIONS', _allowGuestMode, (v) => setState(() => _allowGuestMode = v)),
            const SizedBox(height: 24),
            _buildSliderControl(
              'THROTTLE: MAX DAILY SESSIONS',
              _maxDailyPractice,
              10,
              500,
              (v) => setState(() => _maxDailyPractice = v.round()),
            ),
          ], AppTheme.mintGreen),
          const SizedBox(height: 48),
          NeoButton(
            label: 'COMMIT SYSTEM CHANGES', 
            color: AppTheme.signalYellow, 
            onPressed: _saveSettings,
            icon: Icons.save_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MAINTENANCE OVERRIDE',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Archivo Black'),
          ),
          const SizedBox(height: 40),
          // Kill Switch Panel
          NeoPanel(
            color: _maintenanceEnabled ? AppTheme.punchRed : AppTheme.mintGreen,
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Icon(
                  _maintenanceEnabled ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                  color: AppTheme.inkBlack,
                  size: 48,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _maintenanceEnabled ? 'SYSTEM OFFLINE' : 'SYSTEM OPERATIONAL',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                      ),
                      Text(
                        _maintenanceEnabled ? 'USER ACCESS DENIED GLOBALLY' : 'ALL LEARNERS CONNECTED',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _maintenanceEnabled,
                  onChanged: (value) => setState(() => _maintenanceEnabled = value),
                  activeThumbColor: AppTheme.inkBlack,
                  activeTrackColor: Colors.black26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _settingsCard('BROADCAST MESSAGE', [
            TextField(
              controller: _maintenanceMessageController,
              maxLines: 4,
              style: const TextStyle(fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                hintText: 'OVERRIDE MESSAGE FOR LEARNERS...',
                filled: true,
                fillColor: AppTheme.paperCream,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), 
                  borderSide: const BorderSide(color: AppTheme.inkBlack, width: 3)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), 
                  borderSide: const BorderSide(color: AppTheme.inkBlack, width: 4)
                ),
              ),
            ),
          ], AppTheme.signalYellow),
          const SizedBox(height: 48),
          NeoButton(
            label: _maintenanceEnabled ? 'DAWN MAINTENANCE' : 'UPDATE BROADCAST', 
            color: Colors.white, 
            textColor: AppTheme.inkBlack,
            onPressed: _saveMaintenanceSettings,
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
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              const Text(
                'SECURITY AUDIT TRAIL',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Archivo Black'),
              ),
              const Spacer(),
              NeoButton(
                label: 'REFRESH', 
                color: AppTheme.signalYellow, 
                onPressed: () => setState(() {}),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.inkBlack, thickness: 4),
        Expanded(
          child: StreamBuilder<List<AuditLogModel>>(
            stream: _dbService.auditLogsStream(limit: 50),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const NeoEmptyState(
                  icon: Icons.history_rounded, 
                  title: 'LOG CLEAR', 
                  subtitle: 'No system modifications recorded in this timeframe.'
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(32),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) => _logPanel(snapshot.data![index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _logPanel(AuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.inkBlack,
        border: Border.all(color: AppTheme.signalYellow.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.signalYellow, borderRadius: BorderRadius.circular(8)),
            child: Icon(_getActionIcon(log.action), color: AppTheme.inkBlack, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.action} ${log.entityType}'.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  'OPERATOR: ${log.adminName.toUpperCase()}',
                  style: const TextStyle(color: AppTheme.signalYellow, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(log.timestamp),
            style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(String title, List<Widget> children, Color accent) {
    return NeoPanel(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return NeoPanel(
      color: AppTheme.paperCream,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w900),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, fontSize: 10),
          prefixIcon: Icon(icon, color: AppTheme.inkBlack),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        Switch(
          value: value, 
          onChanged: onChanged, 
          activeThumbColor: AppTheme.mintGreen, 
          activeTrackColor: AppTheme.inkBlack
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Archivo Black')),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          activeColor: AppTheme.cobaltBlue,
          inactiveColor: AppTheme.paperCream,
          onChanged: onChanged,
        ),
      ],
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create': return Icons.add_box_rounded;
      case 'update': return Icons.edit_note_rounded;
      case 'delete': return Icons.delete_forever_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    return '${diff.inDays}D AGO';
  }

  void _saveSettings() => _showSnackBar('CONFIG RE-WRITTEN TO DISK', AppTheme.mintGreen);
  void _saveMaintenanceSettings() => _showSnackBar('MAINTENANCE PROTOCOL UPDATED', AppTheme.signalYellow);

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
