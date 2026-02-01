import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';

/// Admin Dashboard - Main overview with statistics and quick actions
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();

  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
  static const Color primaryBlue = Color(0xFF1A2151);
  static const Color cardBg = Color(0xFF262F4D);
  static const Color inputBg = Color(0xFF252A5E);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentBlue = Color(0xFF5CB6F9);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE57373);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentOrange = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkBlue,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        color: accentYellow,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              // Stats Cards
              _buildStatsSection(),
              const SizedBox(height: 24),
              // Two Column Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRecentActivitySection()),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 350,
                          child: Column(
                            children: [
                              _buildQuickActionsSection(),
                              const SizedBox(height: 20),
                              _buildMaintenanceStatusSection(),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildQuickActionsSection(),
                      const SizedBox(height: 20),
                      _buildMaintenanceStatusSection(),
                      const SizedBox(height: 20),
                      _buildRecentActivitySection(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Recent Issues
              _buildRecentIssuesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return FutureBuilder<AdminModel?>(
      future: _adminDbService.getCurrentAdmin(),
      builder: (context, snapshot) {
        final admin = snapshot.data;
        final greeting = _getGreeting();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentYellow.withOpacity(0.15),
                accentBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentYellow.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      admin?.displayName ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Here's your admin dashboard overview",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.waving_hand_rounded,
                color: accentYellow,
                size: 48,
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildStatsSection() {
    return FutureBuilder<AnalyticsSummary>(
      future: _adminDbService.getAnalyticsSummary(),
      builder: (context, snapshot) {
        final stats = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1000
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 2;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Total Learners',
                      '${stats?.totalLearners ?? 0}',
                      Icons.people_rounded,
                      accentPurple,
                      '+${stats?.newLearnersToday ?? 0} today',
                    ),
                    _buildStatCard(
                      'Active Learners',
                      '${stats?.activeLearners ?? 0}',
                      Icons.school_rounded,
                      accentBlue,
                      'Learning now',
                    ),
                    _buildStatCard(
                      'Lessons Completed',
                      '${stats?.totalLessonsCompleted ?? 0}',
                      Icons.fitness_center_rounded,
                      accentGreen,
                      '${stats?.averageAccuracy.toStringAsFixed(1)}% avg accuracy',
                    ),
                    _buildStatCard(
                      'New This Week',
                      '${stats?.newLearnersThisWeek ?? 0}',
                      Icons.trending_up_rounded,
                      accentOrange,
                      'Learners',
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(
                Icons.trending_up,
                color: accentGreen.withOpacity(0.7),
                size: 18,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on_rounded, color: accentYellow, size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickActionButton(
            'Add New Lesson',
            Icons.add_circle_outline,
            accentBlue,
            () {
              // Navigate to add lesson
            },
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            'Add Word Group',
            Icons.text_fields_rounded,
            accentGreen,
            () {
              // Navigate to add word group
            },
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            'View All Issues',
            Icons.bug_report_outlined,
            accentRed,
            () {
              // Navigate to issues
            },
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            'Export Analytics',
            Icons.download_rounded,
            accentPurple,
            () {
              // Export analytics
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceStatusSection() {
    return StreamBuilder<MaintenanceModeModel?>(
      stream: _adminDbService.maintenanceModeStream(),
      builder: (context, snapshot) {
        final maintenance = snapshot.data;
        final isActive = maintenance?.isEnabled ?? false;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(color: accentOrange.withOpacity(0.5), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.engineering_rounded,
                    color: isActive ? accentOrange : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Maintenance Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accentOrange.withOpacity(0.2)
                          : accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'OFF',
                      style: TextStyle(
                        color: isActive ? accentOrange : accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isActive
                    ? maintenance?.message ?? 'App is under maintenance'
                    : 'App is running normally',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              if (isActive && maintenance?.scheduledEnd != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Expected to end: ${_formatDateTime(maintenance!.scheduledEnd!)}',
                  style: TextStyle(
                    color: accentOrange.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: accentBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // View all activity
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: accentBlue.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admin_audit_log')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          color: Colors.white.withOpacity(0.3),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final log = AuditLogModel.fromFirestore(doc);
                  return _buildActivityItem(log);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AuditLogModel log) {
    final color = _getActionColor(log.action);
    final icon = _getActionIcon(log.action);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.action} ${log.entityType}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.adminName} • ${_formatTimeAgo(log.timestamp)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
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

  Widget _buildRecentIssuesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report_rounded, color: accentRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Issues',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to issues page
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: accentBlue.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<IssueModel>>(
            stream: _adminDbService.issuesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: accentGreen.withOpacity(0.5),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No open issues',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final issues = snapshot.data!.take(5).toList();
              return Column(
                children: issues.map((issue) => _buildIssueItem(issue)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem(IssueModel issue) {
    final priorityColor = _getPriorityColor(issue.priority);
    final statusColor = _getStatusColor(issue.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: priorityColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        issue.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      issue.category.displayName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatTimeAgo(issue.createdAt),
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('create') || action.contains('add')) return accentGreen;
    if (action.contains('delete') || action.contains('remove')) return accentRed;
    if (action.contains('update') || action.contains('edit')) return accentBlue;
    return accentYellow;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('create') || action.contains('add')) return Icons.add_circle;
    if (action.contains('delete') || action.contains('remove')) return Icons.remove_circle;
    if (action.contains('update') || action.contains('edit')) return Icons.edit;
    if (action.contains('lesson')) return Icons.school;
    if (action.contains('user') || action.contains('learner')) return Icons.person;
    return Icons.info;
  }

  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.critical:
        return accentRed;
      case IssuePriority.high:
        return accentOrange;
      case IssuePriority.medium:
        return accentYellow;
      case IssuePriority.low:
        return accentGreen;
    }
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return accentRed;
      case IssueStatus.inProgress:
        return accentYellow;
      case IssueStatus.resolved:
        return accentGreen;
      case IssueStatus.closed:
        return Colors.white54;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
