import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  final AdminModel admin;
  final VoidCallback onMenuTap;

  const AdminAnalyticsScreen({
    super.key,
    required this.admin,
    required this.onMenuTap,
  });

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _db = AdminDatabaseService();
  bool _loading = true;
  bool _hasError = false;
  Map<String, dynamic> _analytics = {};
  List<SignPracticeLogModel> _practiceLogs = [];

  List<double> _dailyValues = [];
  List<String> _dailyLabels = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        _db.getAnalyticsSummary(),
        _db.getSignPracticeLogs(limit: 200),
      ]);
      if (!mounted) return;
      final analytics = results[0] as Map<String, dynamic>;
      final logs = results[1] as List<SignPracticeLogModel>;
      _buildChartData(logs);
      setState(() {
        _analytics = analytics;
        _practiceLogs = logs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  void _buildChartData(List<SignPracticeLogModel> logs) {
    final now = DateTime.now();
    final Map<String, int> dayMap = {};
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      dayMap[key] = 0;
    }
    
    for (final log in logs) {
      final t = log.timestamp;
      final diff = now.difference(t).inDays;
      if (diff < 7) {
        final key = '${t.year}-${t.month}-${t.day}';
        if (dayMap.containsKey(key)) {
          dayMap[key] = dayMap[key]! + 1;
        }
      }
    }
    
    _dailyValues = dayMap.values.map((v) => v.toDouble()).toList();
    _dailyLabels = [];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      _dailyLabels.add(days[d.weekday % 7]);
    }
  }

  List<_TopSign> _getTopSigns() {
    final Map<String, int> counts = {};
    for (final log in _practiceLogs) {
      counts[log.signId] = (counts[log.signId] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).map((e) => _TopSign(e.key, e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: AdminTopBar(title: 'Analytics', onMenuTap: widget.onMenuTap),
        body: AdminSkeletonLoader.listRows(count: 10),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: c.bgBase,
        appBar: AdminTopBar(title: 'Analytics', onMenuTap: widget.onMenuTap),
        body: AdminErrorState(onRetry: _loadData),
      );
    }

    final topSigns = _getTopSigns();
    final activeCount = _analytics['activeLearners'] ?? 0;
    final totalCount = _analytics['totalLearners'] ?? 0;
    final engagementRate = totalCount > 0 ? (activeCount / totalCount) : 0.0;

    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'Analytics',
        onMenuTap: widget.onMenuTap,
        action: AdminTopBarIconButton(
          icon: LucideIcons.refreshCcw,
          onTap: _loadData,
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
              // Summary Row
              Row(
                children: [
                  Expanded(
                    child: _ReportCard(
                      label: 'ACTIVE RATIO',
                      value: '${(engagementRate * 100).toStringAsFixed(1)}%',
                      meta: '$activeCount / $totalCount users',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReportCard(
                      label: 'GROWTH (7D)',
                      value: '+${_analytics['newLearnersThisWeek'] ?? 0}',
                      meta: 'new registrations',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chart
              AdminSectionHeader(title: 'Daily practice engagement'),
              AdminCard(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: AdminBarChart(
                  values: _dailyValues.isEmpty ? [0,0,0,0,0,0,0] : _dailyValues,
                  labels: _dailyLabels.isEmpty ? ['S','M','T','W','T','F','S'] : _dailyLabels,
                ),
              ),
              const SizedBox(height: 24),

              // Engagement Card
              AdminSectionHeader(title: 'System performance'),
              AdminCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('User retention', style: adminH3(c.textPrimary)),
                        Text('${(engagementRate * 100).toInt()}%', style: adminH3(c.accent)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AdminProgressBar(value: engagementRate),
                    const SizedBox(height: 12),
                    Text(
                      'Monitoring active users within the last 7 days compared to cumulative registrations.',
                      style: adminBodySm(c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Top Signs
              AdminSectionHeader(title: 'High-frequency sign usage'),
              AdminCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: topSigns.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('Insufficient data for patterns')),
                          )
                        ]
                      : topSigns.asMap().entries.map((e) {
                          final i = e.key;
                          final s = e.value;
                          return AdminRow(
                            isLast: i == topSigns.length - 1,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c.bgSurface2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: adminLabel(c.textMuted),
                                ),
                              ),
                            ),
                            title: Text(s.signId, style: adminH3(c.textPrimary)),
                            trailing: Text(
                              '${s.count} sessions',
                              style: adminMeta(c.textSecondary),
                            ),
                          );
                        }).toList(),
                ),
              ),

              const SizedBox(height: bottomBuf),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final String meta;

  const _ReportCard({
    required this.label,
    required this.value,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: adminLabel(c.textMuted)),
          const SizedBox(height: 12),
          Text(value, style: statValue(c.textPrimary)),
          const SizedBox(height: 4),
          Text(meta, style: adminMeta(c.textSecondary)),
        ],
      ),
    );
  }
}

class _TopSign {
  final String signId;
  final int count;
  _TopSign(this.signId, this.count);
}
