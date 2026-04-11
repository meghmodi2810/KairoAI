import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.charcoalNight,
      child: FutureBuilder<AnalyticsSummary>(
        future: _adminDbService.getAnalyticsSummary(),
        builder: (context, snapshot) {
          final isLoading = !snapshot.hasData;
          final data = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildKeyMetrics(data, isLoading),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildGrowthSection(data, isLoading)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildPerformanceSection(data, isLoading)),
                  ],
                ),
                const SizedBox(height: 32),
                _buildRecentActivity(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.signalYellow,
                border: Border.all(color: AppTheme.inkBlack, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SYSTEM STATUS: ACTIVE',
                style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.inkBlack, fontSize: 12),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Divider(color: AppTheme.inkBlack, thickness: 3),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'PLATFORM INTELLIGENCE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            fontFamily: 'Archivo Black',
            letterSpacing: -1,
          ),
        ),
        Text(
          'REAL-TIME PERFORMANCE MONITORING & USER MANIFESTS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetrics(AnalyticsSummary? data, bool isLoading) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildLargeMetric(
          'LEARNER BASE',
          isLoading ? '...' : '${data!.totalLearners}',
          '+${data?.newLearnersThisMonth ?? 0} NEW',
          AppTheme.electricBlue,
          Icons.people_alt_rounded,
        ),
        _buildLargeMetric(
          'ENGAGEMENT',
          isLoading ? '...' : '${_calculatePercentage(data?.activeLearners ?? 0, data?.totalLearners ?? 1)}%',
          '${data?.activeLearners ?? 0} ACTIVE',
          AppTheme.mintGreen,
          Icons.sensors_rounded,
        ),
        _buildLargeMetric(
          'CURRICULUM',
          isLoading ? '...' : '${data!.totalLessonsCompleted}',
          'COMPLETED UNITS',
          AppTheme.signalYellow,
          Icons.history_edu_rounded,
        ),
        _buildLargeMetric(
          'LATENCY',
          isLoading ? '...' : '${data!.averageResponseTime}ms',
          'ENGINE SPEED',
          AppTheme.punchRed,
          Icons.speed_rounded,
        ),
      ],
    );
  }

  Widget _buildLargeMetric(String label, String value, String sub, Color color, IconData icon) {
    return NeoPanel(
      color: AppTheme.inkBlack,
      padding: const EdgeInsets.all(24),
      shadowOffset: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
              ),
              Icon(icon, color: color.withValues(alpha: 0.5), size: 20),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontFamily: 'Archivo Black',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub.toUpperCase(),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthSection(AnalyticsSummary? data, bool isLoading) {
    return NeoPanel(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppTheme.inkBlack, size: 28),
              SizedBox(width: 12),
              Text(
                'GROWTH MANIFEST',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _growthSegment('TODAY', '${data?.newLearnersToday ?? 0}', AppTheme.softPeach),
              _growthSegment('WEEKLY', '${data?.newLearnersThisWeek ?? 0}', AppTheme.mintGreen),
              _growthSegment('MONTHLY', '${data?.newLearnersThisMonth ?? 0}', AppTheme.electricBlue),
            ],
          ),
          const SizedBox(height: 32),
          // Placeholder for a chart or more detailed growth stats
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.paperCream,
              border: Border.all(color: AppTheme.inkBlack, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_graph_rounded, color: AppTheme.inkBlack.withValues(alpha: 0.2), size: 48),
                  const SizedBox(height: 8),
                  Text('GROWTH TRAJECTORY OPTIMIZED', 
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.inkBlack.withValues(alpha: 0.3))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _growthSegment(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppTheme.inkBlack, width: 3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.hardShadow(offset: 4),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, fontFamily: 'Archivo Black'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection(AnalyticsSummary? data, bool isLoading) {
    return NeoPanel(
      color: AppTheme.signalYellow,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENGINE FIDELITY',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
          ),
          const SizedBox(height: 24),
          _perfItem('ACCURACY', '${data?.averageAccuracy.toStringAsFixed(1) ?? 0}%'),
          const SizedBox(height: 16),
          _perfItem('SUCCESS', '${data?.totalLessonsCompleted ?? 0} UNITS'),
          const SizedBox(height: 32),
          const Text(
            'LESSON VELOCITY',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (data != null && data.lessonCompletionRates.isNotEmpty)
            ...data.lessonCompletionRates.entries.take(3).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMiniProgress(e.key, e.value.toDouble()),
            )),
        ],
      ),
    );
  }

  Widget _perfItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, fontFamily: 'Archivo Black')),
      ],
    );
  }

  Widget _buildMiniProgress(String label, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 9)),
            Text('${val.toInt()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            border: Border.all(color: AppTheme.inkBlack, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: val / 100,
            child: Container(color: AppTheme.inkBlack),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return NeoPanel(
      color: AppTheme.inkBlack,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal_rounded, color: AppTheme.mintGreen, size: 24),
              SizedBox(width: 12),
              Text(
                'SYSTEM AUDIT LOGS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
              ),
              Spacer(),
              Text('VIEW FULL MANIFEST', 
                style: TextStyle(color: AppTheme.mintGreen, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 32),
          StreamBuilder<List<AuditLogModel>>(
            stream: _adminDbService.auditLogsStream(limit: 8),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('NO RECENT MODIFICATIONS DETECTED', 
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900)),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.map((log) => _buildLogItem(log)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(AuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(left: BorderSide(color: _getLogColor(log.action), width: 6)),
      ),
      child: Row(
        children: [
          Text(
            '[${_formatTime(log.timestamp).toUpperCase()}]',
            style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: log.adminName.toUpperCase(), style: TextStyle(color: _getLogColor(log.action))),
                  const TextSpan(text: ' EXECUTED '),
                  TextSpan(text: log.action.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  const TextSpan(text: ' ON '),
                  TextSpan(text: log.entityType.toUpperCase(), style: const TextStyle(color: AppTheme.signalYellow)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String action) {
    switch (action.toLowerCase()) {
      case 'create': return AppTheme.mintGreen;
      case 'update': return AppTheme.electricBlue;
      case 'delete': return AppTheme.punchRed;
      default: return AppTheme.signalYellow;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  int _calculatePercentage(int value, int total) {
    if (total == 0) return 0;
    return ((value / total) * 100).round();
  }
}
