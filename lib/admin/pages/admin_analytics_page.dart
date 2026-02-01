import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';

/// Admin Analytics Page - View platform metrics and statistics
class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();

  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
  static const Color cardBg = Color(0xFF262F4D);
  static const Color inputBg = Color(0xFF252A5E);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentBlue = Color(0xFF5CB6F9);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE57373);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentPurple = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkBlue,
      child: FutureBuilder<AnalyticsSummary>(
        future: _adminDbService.getAnalyticsSummary(),
        builder: (context, snapshot) {
          final isLoading = !snapshot.hasData;
          final data = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Analytics Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor platform performance and user engagement',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 24),
                // Key Metrics
                _buildKeyMetrics(data, isLoading),
                const SizedBox(height: 24),
                // Growth Section
                _buildGrowthSection(data, isLoading),
                const SizedBox(height: 24),
                // Performance Section
                _buildPerformanceSection(data, isLoading),
                const SizedBox(height: 24),
                // Recent Activity
                _buildRecentActivity(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeyMetrics(AnalyticsSummary? data, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          children: [
            _buildMetricCard(
              'Total Learners',
              isLoading ? '-' : '${data!.totalLearners}',
              '+${data?.newLearnersThisMonth ?? 0} this month',
              Icons.people_rounded,
              accentPurple,
              isLoading,
            ),
            _buildMetricCard(
              'Active Learners',
              isLoading ? '-' : '${data!.activeLearners}',
              '${_calculatePercentage(data?.activeLearners ?? 0, data?.totalLearners ?? 1)}% of total',
              Icons.person_pin_rounded,
              accentGreen,
              isLoading,
            ),
            _buildMetricCard(
              'Lessons Completed',
              isLoading ? '-' : '${data!.totalLessonsCompleted}',
              '${data?.averageAccuracy.toStringAsFixed(1) ?? 0}% avg accuracy',
              Icons.school_rounded,
              accentBlue,
              isLoading,
            ),
            _buildMetricCard(
              'Avg Response Time',
              isLoading ? '-' : '${data!.averageResponseTime}ms',
              'Response performance',
              Icons.timer_rounded,
              accentOrange,
              isLoading,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: accentYellow))
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGrowthSection(AnalyticsSummary? data, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Growth',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildGrowthCard(
                  'Today',
                  isLoading ? '-' : '${data!.newLearnersToday}',
                  Icons.today,
                  accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGrowthCard(
                  'This Week',
                  isLoading ? '-' : '${data!.newLearnersThisWeek}',
                  Icons.calendar_view_week,
                  accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGrowthCard(
                  'This Month',
                  isLoading ? '-' : '${data!.newLearnersThisMonth}',
                  Icons.calendar_month,
                  accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(AnalyticsSummary? data, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Average Accuracy',
                  isLoading ? '-' : '${data!.averageAccuracy.toStringAsFixed(1)}%',
                  _getAccuracyColor(data?.averageAccuracy ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceCard(
                  'Response Time',
                  isLoading ? '-' : '${data!.averageResponseTime}ms',
                  accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceCard(
                  'Total Lessons',
                  isLoading ? '-' : '${data!.totalLessonsCompleted}',
                  accentPurple,
                ),
              ),
            ],
          ),
          // Lesson completion rates if available
          if (data != null && data.lessonCompletionRates.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Lesson Completion Rates',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ...data.lessonCompletionRates.entries.take(5).map((entry) {
              final percentage = entry.value.toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildProgressBar(entry.key, percentage),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: accentYellow,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: inputBg,
          valueColor: AlwaysStoppedAnimation(_getAccuracyColor(percentage)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<AuditLogModel>>(
            stream: _adminDbService.auditLogsStream(limit: 10),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.map((log) => _buildActivityItem(log)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AuditLogModel log) {
    final color = _getActionColor(log.action);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getActionIcon(log.action), color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.action} ${log.entityType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${log.adminName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
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

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return accentGreen;
    if (accuracy >= 60) return accentYellow;
    if (accuracy >= 40) return accentOrange;
    return accentRed;
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

  int _calculatePercentage(int value, int total) {
    if (total == 0) return 0;
    return ((value / total) * 100).round();
  }
}
