import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../widgets/admin_widgets.dart';

class IssuesManagementPage extends StatefulWidget {
  final AdminModel admin;

  const IssuesManagementPage({super.key, required this.admin});

  @override
  State<IssuesManagementPage> createState() => _IssuesManagementPageState();
}

class _IssuesManagementPageState extends State<IssuesManagementPage> {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  String _filterStatus = 'all';
  String _filterPriority = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildIssuesList()),
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
          Text('Issues & Feedback', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
          SizedBox(height: 2),
          Text('Manage user reports', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'open', 'in_progress', 'resolved'].map((status) {
                final isSelected = _filterStatus == status;
                final labels = {'all': 'All', 'open': 'Open', 'in_progress': 'In Progress', 'resolved': 'Resolved'};
                final colors = {'all': AdminTheme.textPrimary, 'open': AdminTheme.error, 'in_progress': AdminTheme.warning, 'resolved': AdminTheme.success};
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labels[status]!),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterStatus = status),
                    backgroundColor: AdminTheme.cardBg,
                    selectedColor: colors[status]!.withOpacity(0.3),
                    labelStyle: TextStyle(fontSize: 12, color: isSelected ? colors[status] : AdminTheme.textSecondary),
                    checkmarkColor: colors[status],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'critical', 'high', 'medium', 'low'].map((priority) {
                final isSelected = _filterPriority == priority;
                final labels = {'all': 'All', 'critical': 'Critical', 'high': 'High', 'medium': 'Medium', 'low': 'Low'};
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(labels[priority]!, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterPriority = priority),
                    backgroundColor: AdminTheme.cardBg,
                    selectedColor: AdminTheme.accentYellow,
                    labelStyle: TextStyle(color: isSelected ? AdminTheme.primaryDark : AdminTheme.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesList() {
    return StreamBuilder<List<IssueModel>>(
      stream: _dbService.issuesStream(
        status: _filterStatus == 'all' ? null : _filterStatus,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow)));
        }

        var issues = snapshot.data ?? [];
        if (_filterPriority != 'all') {
          issues = issues.where((i) => i.priority == _filterPriority).toList();
        }

        if (issues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_outline, size: 48, color: AdminTheme.success),
                SizedBox(height: 12),
                Text('No Issues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                Text('All clear!', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: AdminTheme.accentYellow,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            itemBuilder: (context, index) => _buildIssueCard(issues[index]),
          ),
        );
      },
    );
  }

  Widget _buildIssueCard(IssueModel issue) {
    final priorityColors = {
      'critical': AdminTheme.error,
      'high': AdminTheme.accentPink,
      'medium': AdminTheme.warning,
      'low': AdminTheme.info,
    };
    final statusColors = {
      'open': AdminTheme.error,
      'in_progress': AdminTheme.warning,
      'resolved': AdminTheme.success,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showIssueDetails(issue),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (priorityColors[issue.priority] ?? AdminTheme.info).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(issue.priority.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColors[issue.priority])),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (statusColors[issue.status] ?? AdminTheme.info).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(issue.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColors[issue.status])),
                  ),
                  const Spacer(),
                  Text(_formatDate(issue.createdAt), style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              Text(issue.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(issue.description, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: AdminTheme.cardBgLight, borderRadius: BorderRadius.circular(6)),
                    child: Text(issue.type, style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
                  ),
                  const Spacer(),
                  Text('By: ${issue.reportedBy}', style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIssueDetails(IssueModel issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _buildIssueDetailsSheet(issue, controller),
      ),
    );
  }

  Widget _buildIssueDetailsSheet(IssueModel issue, ScrollController controller) {
    final priorityColors = {'critical': AdminTheme.error, 'high': AdminTheme.accentPink, 'medium': AdminTheme.warning, 'low': AdminTheme.info};
    final statusColors = {'open': AdminTheme.error, 'in_progress': AdminTheme.warning, 'resolved': AdminTheme.success};

    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: (priorityColors[issue.priority] ?? AdminTheme.info).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(issue.priority.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColors[issue.priority])),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: (statusColors[issue.status] ?? AdminTheme.info).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(issue.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColors[issue.status])),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(issue.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(issue.description, style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
          const SizedBox(height: 20),
          // Details
          _buildDetailRow('Type', issue.type),
          _buildDetailRow('Reporter', issue.reportedBy),
          _buildDetailRow('Created', _formatDateTime(issue.createdAt)),
          if (issue.resolvedAt != null) _buildDetailRow('Resolved', _formatDateTime(issue.resolvedAt!)),
          const SizedBox(height: 20),
          // Actions
          const Text('Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          if (issue.status != 'resolved') ...[
            Row(
              children: [
                if (issue.status == 'open')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateIssueStatus(issue, 'in_progress'),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.warning, foregroundColor: AdminTheme.primaryDark),
                    ),
                  ),
                if (issue.status == 'open') const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateIssueStatus(issue, 'resolved'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () { Navigator.pop(context); _deleteIssue(issue); },
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.error, side: const BorderSide(color: AdminTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  Future<void> _updateIssueStatus(IssueModel issue, String newStatus) async {
    Navigator.pop(context);
    await _dbService.updateIssue(issue.id, {
      'status': newStatus,
      if (newStatus == 'resolved') 'resolvedAt': DateTime.now(),
      if (newStatus == 'in_progress') 'assignedTo': widget.admin.displayName,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to ${newStatus.replaceAll('_', ' ')}')));
  }

  Future<void> _deleteIssue(IssueModel issue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Issue?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${issue.title}"?', style: const TextStyle(color: AdminTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _dbService.deleteIssue(issue.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue deleted')));
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _formatDateTime(DateTime date) => '${_formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
