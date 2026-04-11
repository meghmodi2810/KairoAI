import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

/// Admin Issues Management Page - Handle user feedback and issues
class AdminIssuesPage extends StatefulWidget {
  const AdminIssuesPage({super.key});

  @override
  State<AdminIssuesPage> createState() => _AdminIssuesPageState();
}

class _AdminIssuesPageState extends State<AdminIssuesPage> {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  String _categoryFilter = 'all';
  String _searchQuery = '';
  IssueModel? _selectedIssue;

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return AppTheme.punchRed;
      case IssueStatus.inProgress:
        return AppTheme.signalYellow;
      case IssueStatus.resolved:
        return AppTheme.mintGreen;
      case IssueStatus.closed:
        return AppTheme.inkBlack.withValues(alpha: 0.5);
    }
  }

  String _getStatusText(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return 'NEW';
      case IssueStatus.inProgress:
        return 'WORKING';
      case IssueStatus.resolved:
        return 'RESOLVED';
      case IssueStatus.closed:
        return 'CLOSED';
    }
  }

  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return AppTheme.electricBlue;
      case IssuePriority.medium:
        return AppTheme.signalYellow;
      case IssuePriority.high:
        return const Color(0xFFFF9800);
      case IssuePriority.critical:
        return AppTheme.punchRed;
    }
  }

  String _getPriorityText(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return 'LOW';
      case IssuePriority.medium:
        return 'MEDIUM';
      case IssuePriority.high:
        return 'HIGH';
      case IssuePriority.critical:
        return 'CRITICAL';
    }
  }

  IconData _getCategoryIcon(IssueCategory category) {
    switch (category) {
      case IssueCategory.bug:
        return Icons.bug_report_rounded;
      case IssueCategory.featureRequest:
        return Icons.lightbulb_rounded;
      case IssueCategory.contentIssue:
        return Icons.article_rounded;
      case IssueCategory.other:
        return Icons.help_rounded;
    }
  }

  String _getCategoryText(IssueCategory category) {
    switch (category) {
      case IssueCategory.bug:
        return 'BUG';
      case IssueCategory.featureRequest:
        return 'FEATURE';
      case IssueCategory.contentIssue:
        return 'CONTENT';
      case IssueCategory.other:
        return 'OTHER';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.charcoalNight,
      child: Row(
        children: [
          // Issues List
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildFilters(),
                const Divider(height: 4, thickness: 4, color: AppTheme.inkBlack),
                Expanded(child: _buildIssuesList()),
              ],
            ),
          ),
          // Issue Details Panel
          const VerticalDivider(width: 4, thickness: 4, color: AppTheme.inkBlack),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _selectedIssue != null ? 500 : 0,
            color: AppTheme.paperCream,
            child: _selectedIssue != null ? _buildIssueDetails() : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          // Search
          NeoPanel(
            color: AppTheme.paperCream,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'SCAN SIGNAL LOGS...',
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.inkBlack),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter buttons row
          Row(
            children: [
              _filterButton('STATUS', _statusFilter, ['all', 'newIssue', 'inProgress', 'resolved', 'closed'], (v) => setState(() => _statusFilter = v)),
              const SizedBox(width: 12),
              _filterButton('PRIORITY', _priorityFilter, ['all', 'low', 'medium', 'high', 'critical'], (v) => setState(() => _priorityFilter = v)),
              const SizedBox(width: 12),
              _filterButton('TYPE', _categoryFilter, ['all', 'bug', 'feature', 'content', 'other'], (v) => setState(() => _categoryFilter = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, String current, List<String> options, Function(String) onTap) {
    return Expanded(
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.paperCream,
          border: Border.all(color: AppTheme.inkBlack, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.inkBlack),
          items: options.map((opt) => DropdownMenuItem(
            value: opt,
            child: Text(opt.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          )).toList(),
          onChanged: (v) => onTap(v!),
        ),
      ),
    );
  }

  Widget _buildIssuesList() {
    IssueStatus? statusFilter;
    if (_statusFilter != 'all') {
      statusFilter = IssueStatus.fromString(_statusFilter);
    }

    return StreamBuilder<List<IssueModel>>(
      stream: _dbService.issuesStream(status: statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.signalYellow));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const NeoEmptyState(
            icon: Icons.inbox_rounded,
            title: 'NO SIGNALS',
            subtitle: 'Frequency is clear. No active issues detected.',
          );
        }

        var issues = snapshot.data!;

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          issues = issues.where((i) => 
            i.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
            i.learnerName.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
        if (_priorityFilter != 'all') {
          issues = issues.where((i) => i.priority.value == _priorityFilter).toList();
        }
        if (_categoryFilter != 'all') {
          issues = issues.where((i) => i.category.value == _categoryFilter).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: issues.length,
          itemBuilder: (context, index) => _issueItem(issues[index]),
        );
      },
    );
  }

  Widget _issueItem(IssueModel issue) {
    final isSelected = _selectedIssue?.id == issue.id;
    final statusColor = _getStatusColor(issue.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeoPanel(
        color: isSelected ? AppTheme.signalYellow.withValues(alpha: 0.1) : Colors.white,
        padding: const EdgeInsets.all(20),
        child: InkWell(
          onTap: () => setState(() => _selectedIssue = issue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getCategoryIcon(issue.category), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _getCategoryText(issue.category),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(issue.createdAt),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                issue.title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                issue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  NeoSticker(label: _getStatusText(issue.status), color: statusColor),
                  const SizedBox(width: 8),
                  NeoSticker(label: _getPriorityText(issue.priority), color: _getPriorityColor(issue.priority)),
                  const Spacer(),
                  const Icon(Icons.person_rounded, size: 14, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    issue.learnerName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueDetails() {
    final issue = _selectedIssue!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SIGNAL ANALYSIS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
              IconButton(onPressed: () => setState(() => _selectedIssue = null), icon: const Icon(Icons.close_rounded, size: 32)),
            ],
          ),
          const SizedBox(height: 32),
          NeoPanel(
            color: AppTheme.charcoalNight,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  issue.description,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _detailSection('REPORTER', [
            _detailRow('NAME', issue.learnerName),
            _detailRow('EMAIL', issue.learnerEmail),
            _detailRow('SENT', _formatDate(issue.createdAt)),
          ]),
          const SizedBox(height: 16),
          if (issue.deviceInfo != null && issue.deviceInfo!.isNotEmpty)
            _detailSection('TELEMETRY', [
              if (issue.appVersion != null) _detailRow('VERSION', issue.appVersion!),
              ...issue.deviceInfo!.entries.map((e) => _detailRow(e.key.toUpperCase(), e.value.toString().toUpperCase())),
            ]),
          const SizedBox(height: 32),
          const Text('ADMIN ACTIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (issue.status == IssueStatus.newIssue)
                _actionBtn('ACKNOWLEDGE', AppTheme.electricBlue, () => _updateStatus(issue, IssueStatus.inProgress)),
              if (issue.status == IssueStatus.inProgress)
                _actionBtn('RESOLVE', AppTheme.mintGreen, () => _updateStatus(issue, IssueStatus.resolved)),
              if (issue.status == IssueStatus.resolved)
                _actionBtn('CLOSE LOG', AppTheme.inkBlack, () => _updateStatus(issue, IssueStatus.closed)),
              if (issue.status != IssueStatus.newIssue)
                _actionBtn('REOPEN', AppTheme.punchRed, () => _updateStatus(issue, IssueStatus.newIssue)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('NOTES (COMM HEX)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 16),
          _buildNotesList(issue),
          const SizedBox(height: 16),
          NeoPanel(
            color: Colors.white,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'ADD TO LOG...', 
                        border: InputBorder.none, 
                        enabledBorder: InputBorder.none, 
                        focusedBorder: InputBorder.none
                      ),
                    ),
                  ),
                ),
                NeoButton(
                  label: 'SEND', 
                  color: AppTheme.signalYellow, 
                  onPressed: () => _addNote(issue),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1, color: Colors.black54)),
        const SizedBox(height: 8),
        NeoPanel(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 180,
      child: NeoButton(label: label, color: color, onPressed: onTap),
    );
  }

  Widget _buildNotesList(IssueModel issue) {
    if (issue.adminNotes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.paperCream, 
          border: Border.all(color: AppTheme.inkBlack, width: 2), 
          borderRadius: BorderRadius.circular(10)
        ),
        child: const Center(child: Text('LOG EMPTY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black26))),
      );
    }

    return Column(
      children: issue.adminNotes.map((note) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.paperCream, 
          border: Border.all(color: AppTheme.inkBlack, width: 2), 
          borderRadius: BorderRadius.circular(10)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(note.adminName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.electricBlue)),
                const Spacer(),
                Text(_formatDate(note.timestamp), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.note, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      )).toList(),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStatus(IssueModel issue, IssueStatus status) async {
    try {
      await _dbService.updateIssueStatus(issue.id, status);
      setState(() => _selectedIssue = _selectedIssue?.copyWith(status: status));
      _showSnackBar('STATUS UPDATED'.toUpperCase(), AppTheme.mintGreen);
    } catch (e) {
      _showSnackBar('ERROR UPDATING STATUS'.toUpperCase(), AppTheme.punchRed);
    }
  }

  Future<void> _addNote(IssueModel issue) async {
    if (_noteController.text.trim().isEmpty) return;
    try {
      await _dbService.addIssueNote(issue.id, _noteController.text.trim());
      _noteController.clear();
      // Since it's a future build for some parts, we need to refresh the selected issue if it's cached
      // In this impl, the stream should pick up changes if the stream includes notes.
      // But AdminDatabaseService.addIssueNote might not trigger a refresh of the stream unless properly implemented.
      setState(() {});
      _showSnackBar('NOTE ADDED'.toUpperCase(), AppTheme.mintGreen);
    } catch (e) {
      _showSnackBar('ERROR ADDING NOTE'.toUpperCase(), AppTheme.punchRed);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
