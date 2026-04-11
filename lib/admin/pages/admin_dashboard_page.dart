import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

/// Admin Dashboard - Main overview with statistics and quick actions
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.charcoalNight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemStatusHeader(),
            const SizedBox(height: 48),
            _buildStatsGrid(),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildAuditLog()),
                      const SizedBox(width: 32),
                      Expanded(child: Column(
                        children: [
                          _buildQuickActions(),
                          const SizedBox(height: 32),
                          _buildMascotStatus(),
                        ],
                      )),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: 32),
                      _buildAuditLog(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTROL CENTER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                fontFamily: 'Archivo Black',
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _statusLamp(true),
                const SizedBox(width: 8),
                const Text(
                  'ENGINE 1.0.4 // ALL SYSTEMS OPERATIONAL',
                  style: TextStyle(
                    color: AppTheme.mintGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        NeoPanel(
          color: AppTheme.signalYellow,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: const Column(
            children: [
              Text('LOCAL TIME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
              Text('14:42:09', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'monospace')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusLamp(bool active) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppTheme.mintGreen : AppTheme.punchRed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (active ? AppTheme.mintGreen : AppTheme.punchRed).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return FutureBuilder<AnalyticsSummary>(
      future: _adminDbService.getAnalyticsSummary(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          children: [
            _statTile('LEARNER NODES', '${data?.totalLearners ?? 0}', Icons.hub_rounded, AppTheme.electricBlue),
            _statTile('UNIT COMPLETION', '${data?.totalLessonsCompleted ?? 0}', Icons.task_alt_rounded, AppTheme.mintGreen),
            _statTile('THRUPUT ACCURACY', '${data?.averageAccuracy.toInt() ?? 0}%', Icons.analytics_rounded, AppTheme.signalYellow),
            _statTile('ACTIVE SIGNALS', '${data?.activeLearners ?? 0}', Icons.wifi_tethering_rounded, AppTheme.punchRed),
          ],
        );
      },
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return NeoPanel(
      color: AppTheme.inkBlack,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              fontFamily: 'Archivo Black',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLog() {
    return NeoPanel(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM LOGS',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, fontFamily: 'Archivo Black'),
          ),
          const SizedBox(height: 32),
          StreamBuilder<List<AuditLogModel>>(
            stream: _adminDbService.auditLogsStream(limit: 6),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return Column(
                children: snapshot.data!.map((log) => _auditItem(log)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _auditItem(AuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.paperCream,
        border: Border.all(color: AppTheme.inkBlack, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.inkBlack,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.code_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${log.adminName} executed ${log.action} on ${log.entityType}'.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
          Text(
            _formatTimestamp(log.timestamp),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return NeoPanel(
      color: AppTheme.softPeach,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMMANDS',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Archivo Black'),
          ),
          const SizedBox(height: 24),
          NeoButton(label: 'NEW LESSON', color: AppTheme.cobaltBlue, onPressed: () {}, icon: Icons.add_to_photos_rounded),
          const SizedBox(height: 16),
          NeoButton(label: 'BROADCAST MSG', color: AppTheme.inkBlack, onPressed: () {}, icon: Icons.campaign_rounded),
          const SizedBox(height: 16),
          NeoButton(label: 'CLEAR CACHE', color: Colors.white, textColor: AppTheme.inkBlack, onPressed: () {}, icon: Icons.delete_sweep_rounded),
        ],
      ),
    );
  }

  Widget _buildMascotStatus() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.signalYellow,
        border: Border.all(color: AppTheme.inkBlack, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.hardShadow(offset: 8),
      ),
      child: const Column(
        children: [
          Icon(Icons.face_retouching_natural_rounded, size: 48),
          SizedBox(height: 12),
          Text(
            'MASCOT SYNC: 100%',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          Text(
            'Emotion engine stable',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
