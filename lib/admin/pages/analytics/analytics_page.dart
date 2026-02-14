import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../widgets/admin_widgets.dart';

class AnalyticsPage extends StatefulWidget {
  final AdminModel admin;

  const AnalyticsPage({super.key, required this.admin});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  Map<String, int> _contentCounts = {};
  List<SignPracticeLogModel> _recentPractices = [];
  Map<String, double> _signAccuracy = {};
  String _selectedTimeRange = '7d';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final analytics = await _dbService.getAnalyticsSummary();
      final practices = await _dbService.getSignPracticeLogs(limit: 50);
      final contentCounts = await _loadContentCounts();
      final signAccuracy = _calculateSignAccuracy(practices);
      
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _recentPractices = practices;
          _contentCounts = contentCounts;
          _signAccuracy = signAccuracy;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<Map<String, int>> _loadContentCounts() async {
    try {
      final results = await Future.wait([
        _firestore.collection('categories').get(),
        _firestore.collection('signs').get(),
        _firestore.collectionGroup('lessons').get(),
        _firestore.collection('word_groups').get(),
      ]);
      return {
        'categories': results[0].docs.length,
        'signs': results[1].docs.length,
        'lessons': results[2].docs.length,
        'wordGroups': results[3].docs.length,
      };
    } catch (_) {
      return {'categories': 0, 'signs': 0, 'lessons': 0, 'wordGroups': 0};
    }
  }

  Map<String, double> _calculateSignAccuracy(List<SignPracticeLogModel> practices) {
    if (practices.isEmpty) return {};
    final Map<String, List<bool>> perSign = {};
    for (final p in practices) {
      perSign.putIfAbsent(p.signId, () => []).add(p.isCorrect);
    }
    final sorted = perSign.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final top = sorted.take(8);
    return {
      for (final e in top) e.key: e.value.where((v) => v).length / e.value.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow)))
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: AdminTheme.accentYellow,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildOverviewStats(),
                    const SizedBox(height: 16),
                    _buildContentOverview(),
                    const SizedBox(height: 16),
                    _buildEngagementStats(),
                    const SizedBox(height: 16),
                    _buildSignAccuracy(),
                    const SizedBox(height: 16),
                    _buildRecentActivity(),
                    const SizedBox(height: 16),
                    _buildTopPerformers(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                  SizedBox(height: 2),
                  Text('Platform insights & stats', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                ],
              ),
            ),
            IconButton(onPressed: _loadAnalytics, icon: const Icon(Icons.refresh, size: 20), tooltip: 'Refresh'),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['7d', '30d', 'all'].map((range) {
              final isSelected = _selectedTimeRange == range;
              final labels = {'7d': '7 Days', '30d': '30 Days', 'all': 'All'};
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(labels[range]!),
                  selected: isSelected,
                  onSelected: (_) { setState(() => _selectedTimeRange = range); _loadAnalytics(); },
                  backgroundColor: AdminTheme.cardBg,
                  selectedColor: AdminTheme.accentYellow,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AdminTheme.primaryDark : AdminTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: AdminTheme.primaryDark,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStats() {
    final stats = [
      _StatData('Learners', '${_analytics['totalLearners'] ?? 0}', Icons.people, AdminTheme.info),
      _StatData('Active', '${_analytics['activeLearnersToday'] ?? 0}', Icons.trending_up, AdminTheme.success),
      _StatData('Sessions', '${_analytics['totalPracticeSessions'] ?? 0}', Icons.fitness_center, AdminTheme.accentYellow),
      _StatData('Lessons', '${_analytics['totalLessons'] ?? 0}', Icons.school, AdminTheme.accentPink),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: stat.color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Icon(stat.icon, color: stat.color, size: 18),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(stat.label, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEngagementStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.insights, color: AdminTheme.accentYellow, size: 18),
              SizedBox(width: 8),
              Text('Engagement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Avg. Streak', '${(_analytics['avgStreak'] ?? 0).toStringAsFixed(1)} days', 0.65, AdminTheme.accentPink),
          const SizedBox(height: 12),
          _buildMetricRow('Completion Rate', '${((_analytics['completionRate'] ?? 0) * 100).toStringAsFixed(1)}%', _analytics['completionRate'] ?? 0, AdminTheme.success),
          const SizedBox(height: 12),
          _buildMetricRow('Daily Active', '${((_analytics['dauRate'] ?? 0) * 100).toStringAsFixed(1)}%', _analytics['dauRate'] ?? 0, AdminTheme.info),
          const SizedBox(height: 12),
          _buildMetricRow('Avg. Level', '${(_analytics['avgLevel'] ?? 0).toStringAsFixed(1)}', (_analytics['avgLevel'] ?? 0) / 10, AdminTheme.accentYellow),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildContentOverview() {
    final items = [
      _StatData('Categories', '${_contentCounts['categories'] ?? 0}', Icons.category_rounded, AdminTheme.accentPink),
      _StatData('Signs', '${_contentCounts['signs'] ?? 0}', Icons.sign_language_rounded, AdminTheme.success),
      _StatData('Lessons', '${_contentCounts['lessons'] ?? 0}', Icons.school_rounded, AdminTheme.info),
      _StatData('Word Groups', '${_contentCounts['wordGroups'] ?? 0}', Icons.text_fields_rounded, AdminTheme.accentYellow),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2_rounded, color: AdminTheme.accentPink, size: 18),
              SizedBox(width: 8),
              Text('Content Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: item.color.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(item.icon, color: item.color, size: 20),
                      const SizedBox(height: 6),
                      Text(item.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: item.color)),
                      const SizedBox(height: 2),
                      Text(item.label, style: const TextStyle(fontSize: 9, color: AdminTheme.textSecondary), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSignAccuracy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.sign_language_rounded, color: AdminTheme.success, size: 18),
              SizedBox(width: 8),
              Text('Sign Recognition Accuracy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Top practiced signs', style: TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
          const SizedBox(height: 12),
          if (_signAccuracy.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No practice data yet', style: TextStyle(color: AdminTheme.textSecondary))),
            )
          else
            ..._signAccuracy.entries.map((e) {
              final accuracy = e.value;
              final color = accuracy >= 0.8
                  ? AdminTheme.success
                  : accuracy >= 0.5
                      ? AdminTheme.accentYellow
                      : AdminTheme.error;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  e.key.length == 1 ? e.key.toUpperCase() : e.key[0].toUpperCase(),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(e.key, style: const TextStyle(fontSize: 12, color: AdminTheme.textPrimary)),
                          ],
                        ),
                        Text('${(accuracy * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: accuracy,
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.history, color: AdminTheme.info, size: 18),
              SizedBox(width: 8),
              Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentPractices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No activity yet', style: TextStyle(color: AdminTheme.textSecondary)),
              ),
            )
          else
            ...(_recentPractices.take(5).map((p) => _buildActivityItem(p)).toList()),
        ],
      ),
    );
  }

  Widget _buildActivityItem(SignPracticeLogModel practice) {
    final now = DateTime.now();
    final diff = now.difference(practice.timestamp);
    String timeAgo = diff.inMinutes < 60
        ? '${diff.inMinutes}m'
        : diff.inHours < 24
            ? '${diff.inHours}h'
            : '${diff.inDays}d';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdminTheme.cardBgLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: practice.isCorrect ? AdminTheme.success.withOpacity(0.2) : AdminTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              practice.isCorrect ? Icons.check : Icons.close,
              color: practice.isCorrect ? AdminTheme.success : AdminTheme.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(practice.signId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AdminTheme.textPrimary)),
                Text('${(practice.confidenceScore * 100).toStringAsFixed(0)}% confidence', style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
              ],
            ),
          ),
          Text(timeAgo, style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTopPerformers() {
    final topLearners = _analytics['topLearners'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events, color: AdminTheme.accentYellow, size: 18),
              SizedBox(width: 8),
              Text('Top Performers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          if (topLearners.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No data yet', style: TextStyle(color: AdminTheme.textSecondary))),
            )
          else
            ...topLearners.take(5).toList().asMap().entries.map((e) => _buildPerformerRow(e.value, e.key + 1)).toList(),
        ],
      ),
    );
  }

  Widget _buildPerformerRow(Map<String, dynamic> learner, int rank) {
    final colors = [AdminTheme.accentYellow, Colors.grey.shade400, Colors.brown.shade400, AdminTheme.textSecondary, AdminTheme.textSecondary];
    final color = colors[rank - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: rank <= 3 ? color.withOpacity(0.1) : AdminTheme.cardBgLight,
        borderRadius: BorderRadius.circular(8),
        border: rank <= 3 ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
            child: Center(
              child: rank <= 3
                  ? Icon(Icons.emoji_events, color: color, size: 14)
                  : Text('#$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: AdminTheme.primaryBlue,
            child: Text((learner['name'] as String? ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(learner['name'] ?? 'Unknown', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AdminTheme.textPrimary), overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AdminTheme.accentYellow.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
            child: Text('${learner['xp'] ?? 0} XP', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.accentYellow)),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}
