import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';
import 'package:kairo_ai/models/app_models.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminModel admin;
  final VoidCallback onMenuTap;
  final Function(int, {int? subIndex}) onTabChange;

  const AdminDashboardScreen({
    super.key,
    required this.admin,
    required this.onMenuTap,
    required this.onTabChange,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = AdminDatabaseService();
  bool _loading = true;
  String? _error;

  int _totalUsers = 0;
  int _activeLearners = 0;
  int _openIssues = 0;
  List<AuditLogModel> _recentActivity = [];
  List<UserModel> _recentLearners = [];
  List<double> _chartValues = [0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Get Summary Stats
      final summary = await _db.getAnalyticsSummary();

      // 2. Get Recent Activity
      final activity = await _db.auditLogsStream(limit: 5).first;

      // 3. Get Recent Learners
      final learnersResult = await _db.getLearners(limit: 5);

      // 4. Get chart data
      final chartData = await _getRealChartData();

      if (!mounted) return;
      setState(() {
        _totalUsers = summary['totalLearners'] as int;
        _activeLearners = summary['activeLearners'] as int;
        _openIssues = summary['openIssues'] as int;
        _recentActivity = activity;
        _recentLearners = learnersResult.learners;
        _chartValues = chartData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<double>> _getRealChartData() async {
    return await _db.getDailyLessonCompletions();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: AdminTopBar(
          title: 'Dashboard',
          onMenuTap: widget.onMenuTap,
          action: AdminTopBarIconButton(
            icon: LucideIcons.bell,
            showBadge: false,
          ),
        ),
        body: AdminSkeletonLoader.listRows(count: 10),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: AdminTopBar(title: 'Dashboard', onMenuTap: widget.onMenuTap),
        body: AdminErrorState(message: _error, onRetry: _loadData),
      );
    }

    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'Dashboard',
        onMenuTap: widget.onMenuTap,
        action: AdminTopBarIconButton(
          icon: LucideIcons.bell,
          showBadge: _openIssues > 0,
          onTap: () => widget.onTabChange(4),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: c.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Block matching HTML
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate().toUpperCase(), style: adminMeta(c.textMuted).copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('${_getGreeting()}, Admin', style: adminH1(c.textPrimary).copyWith(fontSize: 16)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981),
                            border: Border.all(color: c.textPrimary, width: 1),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text('All systems operational', style: adminMeta(c.textSecondary).copyWith(fontSize: 10)),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 10, color: c.border),
                        const SizedBox(width: 8),
                        Text('$_openIssues open issues', style: adminMeta(c.textSecondary).copyWith(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Stat Strip matching HTML
              AdminStatStrip(
                stats: [
                  AdminStat(
                    label: 'Users',
                    value: _formatNumber(_totalUsers),
                    delta: 124, // Matches HTML '+124 this week'
                  ),
                  AdminStat(
                    label: 'Active',
                    value: _formatNumber(_activeLearners),
                    delta: 12, // Matches HTML '+12% today'
                  ),
                  AdminStat(
                    label: 'Accuracy',
                    value: '93%',
                    // Delta is null to match 'avg all users' text
                  ),
                ],
              ),

              // Chart matching HTML
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lessons completed — last 7 days'.toUpperCase(), style: adminLabel(c.textMuted).copyWith(fontSize: 9)),
                    AdminBarChart(
                      values: _chartValues,
                      labels: _getLast7Days(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Recent Learners Rows matching HTML
              AdminSectionHeader(
                title: 'Recent learners',
                actionLabel: 'View all',
                onAction: () => widget.onTabChange(2),
              ),
              ..._recentLearners.asMap().entries.map((e) {
                final i = e.key;
                final learner = e.value;
                return AdminRow(
                  isLast: i == _recentLearners.length - 1,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.accentFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(learner.displayName),
                        style: adminLabel(c.isDark ? c.accentBright : c.accent),
                      ),
                    ),
                  ),
                  title: Text(learner.displayName, style: adminH3(c.textPrimary)),
                  subtitle: Text('Level ${learner.currentLevel} · ${learner.streakDays}d streak', style: adminMeta(c.textMuted)),
                  trailing: AdminTag(
                    label: learner.isActive ? 'Active' : 'Banned',
                    variant: learner.isActive ? AdminTagVariant.active : AdminTagVariant.banned,
                  ),
                  onTap: () {
                    // Navigate to user details
                  },
                );
              }),
              const SizedBox(height: 14),

              // Audit Logs
              AdminSectionHeader(
                title: 'Operation Logs',
                actionLabel: 'Logs',
                onAction: () => widget.onTabChange(5, subIndex: 1),
              ),
              AdminCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _recentActivity.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No recent activity'),
                          )
                        ]
                      : _recentActivity.asMap().entries.map((e) {
                          final i = e.key;
                          final log = e.value;
                          return AdminRow(
                            isLast: i == _recentActivity.length - 1,
                            minHeight: 56,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c.bgSurface2,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: c.border, width: 1.5),
                              ),
                              child: Icon(
                                _actionIcon(log.action),
                                size: 14,
                                color: c.textSecondary,
                              ),
                            ),
                            title: Text(
                              _formatAction(log.action, log.entityType),
                              style: adminH3(c.textPrimary),
                            ),
                            subtitle: Text(
                              _relativeTime(log.timestamp),
                              style: adminMeta(c.textMuted),
                            ),
                            trailing: Text(
                              log.adminEmail.split('@').first,
                              style: adminMeta(c.textSecondary),
                            ),
                          );
                        }).toList(),
                ),
              ),

              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n < 1000) return n.toString();
    return '${(n / 1000).toStringAsFixed(1)}k';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  String _formatAction(String action, String entity) {
    final act = action.toLowerCase();
    final ent = entity.toLowerCase();
    
    if (act == 'create') return 'New $ent added';
    if (act == 'update') return '$ent updated';
    if (act == 'delete') return '$ent removed';
    if (act == 'ban_user') return 'User banned';
    if (act == 'login') return 'Admin logged in';
    
    return '${action.replaceAll('_', ' ')}: $ent';
  }

  IconData _actionIcon(String action) {
    final act = action.toLowerCase();
    if (act.contains('create')) return LucideIcons.plus;
    if (act.contains('update')) return LucideIcons.refreshCcw;
    if (act.contains('delete')) return LucideIcons.trash;
    if (act.contains('ban')) return LucideIcons.ban;
    if (act.contains('login')) return LucideIcons.key;
    return LucideIcons.activity;
  }

  List<String> _getLast7Days() {
    final now = DateTime.now();
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return days[d.weekday % 7];
    });
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
