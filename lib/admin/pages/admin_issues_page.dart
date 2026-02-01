import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';

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
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return accentRed;
      case IssueStatus.inProgress:
        return accentOrange;
      case IssueStatus.resolved:
        return accentGreen;
      case IssueStatus.closed:
        return Colors.grey;
    }
  }

  String _getStatusText(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return 'New';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.resolved:
        return 'Resolved';
      case IssueStatus.closed:
        return 'Closed';
    }
  }

  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return accentBlue;
      case IssuePriority.medium:
        return accentYellow;
      case IssuePriority.high:
        return accentOrange;
      case IssuePriority.critical:
        return accentRed;
    }
  }

  String _getPriorityText(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return 'Low';
      case IssuePriority.medium:
        return 'Medium';
      case IssuePriority.high:
        return 'High';
      case IssuePriority.critical:
        return 'Critical';
    }
  }

  IconData _getCategoryIcon(IssueCategory category) {
    switch (category) {
      case IssueCategory.bug:
        return Icons.bug_report;
      case IssueCategory.featureRequest:
        return Icons.lightbulb;
      case IssueCategory.contentIssue:
        return Icons.article;
      case IssueCategory.other:
        return Icons.help;
    }
  }

  String _getCategoryText(IssueCategory category) {
    switch (category) {
      case IssueCategory.bug:
        return 'Bug';
      case IssueCategory.featureRequest:
        return 'Feature Request';
      case IssueCategory.contentIssue:
        return 'Content Issue';
      case IssueCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkBlue,
      child: Row(
        children: [
          // Issues List
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildFilters(),
                Expanded(child: _buildIssuesList()),
              ],
            ),
          ),
          // Issue Details Panel
          if (_selectedIssue != null)
            Container(
              width: 450,
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: _buildIssueDetails(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          // Search
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search issues...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter dropdowns
          Row(
            children: [
              // Status filter
              Expanded(
                child: _buildFilterDropdown(
                  'Status',
                  _statusFilter,
                  ['all', 'newIssue', 'inProgress', 'resolved', 'closed'],
                  ['All', 'New', 'In Progress', 'Resolved', 'Closed'],
                  (value) => setState(() => _statusFilter = value ?? 'all'),
                ),
              ),
              const SizedBox(width: 8),
              // Priority filter
              Expanded(
                child: _buildFilterDropdown(
                  'Priority',
                  _priorityFilter,
                  ['all', 'low', 'medium', 'high', 'critical'],
                  ['All', 'Low', 'Medium', 'High', 'Critical'],
                  (value) => setState(() => _priorityFilter = value ?? 'all'),
                ),
              ),
              const SizedBox(width: 8),
              // Category filter
              Expanded(
                child: _buildFilterDropdown(
                  'Category',
                  _categoryFilter,
                  ['all', 'bug', 'feature', 'content', 'other'],
                  ['All', 'Bug', 'Feature Request', 'Content Issue', 'Other'],
                  (value) => setState(() => _categoryFilter = value ?? 'all'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String currentValue,
    List<String> values,
    List<String> labels,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: currentValue,
        dropdownColor: cardBg,
        underline: const SizedBox(),
        isExpanded: true,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        items: List.generate(values.length, (i) {
          return DropdownMenuItem(value: values[i], child: Text(labels[i]));
        }),
        onChanged: onChanged,
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
          return const Center(
            child: CircularProgressIndicator(color: accentYellow),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  color: Colors.white.withOpacity(0.3),
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'No issues found',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        var issues = snapshot.data!;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          issues = issues.where((issue) {
            return issue.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                issue.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                issue.learnerName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // Apply priority filter
        if (_priorityFilter != 'all') {
          issues = issues.where((issue) {
            return issue.priority.value == _priorityFilter;
          }).toList();
        }

        // Apply category filter
        if (_categoryFilter != 'all') {
          issues = issues.where((issue) {
            return issue.category.value == _categoryFilter;
          }).toList();
        }

        if (issues.isEmpty) {
          return Center(
            child: Text(
              'No issues match your filters',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            return _buildIssueCard(issues[index]);
          },
        );
      },
    );
  }

  Widget _buildIssueCard(IssueModel issue) {
    final isSelected = _selectedIssue?.id == issue.id;
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? accentBlue.withOpacity(0.1) : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentBlue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIssue = issue),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(issue.category),
                      color: Colors.white.withOpacity(0.6),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description preview
                Text(
                  issue.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Tags row
                Row(
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusText(issue.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getPriorityText(issue.priority),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // User
                    Text(
                      issue.learnerName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssueDetails() {
    if (_selectedIssue == null) return const SizedBox();

    final issue = _selectedIssue!;
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Issue Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _selectedIssue = null),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Title and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  issue.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(_getStatusText(issue.status), statusColor),
              _buildTag(_getPriorityText(issue.priority), priorityColor),
              _buildTag(_getCategoryText(issue.category), accentPurple),
            ],
          ),
          const SizedBox(height: 20),
          // Description
          _buildSection('Description', issue.description),
          const SizedBox(height: 16),
          // Reporter info
          _buildInfoSection('Reporter', [
            _buildInfoRow('Name', issue.learnerName),
            _buildInfoRow('Email', issue.learnerEmail),
            _buildInfoRow('Reported', _formatDate(issue.createdAt)),
          ]),
          const SizedBox(height: 16),
          // Device info
          if (issue.deviceInfo != null && issue.deviceInfo!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Device Info', [
                  if (issue.appVersion != null)
                    _buildInfoRow('App Version', issue.appVersion!),
                  ...issue.deviceInfo!.entries.map((e) => 
                    _buildInfoRow(e.key, e.value.toString())),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          // Admin notes
          _buildAdminNotes(issue),
          const SizedBox(height: 24),
          // Actions
          _buildActions(issue),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotes(IssueModel issue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Admin Notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddNoteDialog(issue),
              icon: const Icon(Icons.add, color: accentBlue, size: 20),
              tooltip: 'Add Note',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (issue.adminNotes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'No admin notes yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...issue.adminNotes.map((note) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          note.adminName,
                          style: const TextStyle(
                            color: accentBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(note.timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note.note,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildActions(IssueModel issue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Status actions
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (issue.status == IssueStatus.newIssue)
              _buildActionButton(
                'Start Working',
                Icons.play_arrow,
                accentBlue,
                () => _updateStatus(issue, IssueStatus.inProgress),
              ),
            if (issue.status == IssueStatus.inProgress)
              _buildActionButton(
                'Mark Resolved',
                Icons.check,
                accentGreen,
                () => _updateStatus(issue, IssueStatus.resolved),
              ),
            if (issue.status == IssueStatus.resolved)
              _buildActionButton(
                'Close Issue',
                Icons.archive,
                Colors.grey,
                () => _updateStatus(issue, IssueStatus.closed),
              ),
            if (issue.status != IssueStatus.newIssue)
              _buildActionButton(
                'Reopen',
                Icons.refresh,
                accentOrange,
                () => _updateStatus(issue, IssueStatus.newIssue),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Priority change
        const Text(
          'Change Priority',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: IssuePriority.values.map((p) {
            final isActive = issue.priority == p;
            return ChoiceChip(
              label: Text(_getPriorityText(p)),
              selected: isActive,
              onSelected: isActive ? null : (_) => _updatePriority(issue, p),
              selectedColor: _getPriorityColor(p).withOpacity(0.3),
              labelStyle: TextStyle(
                color: isActive ? _getPriorityColor(p) : Colors.white70,
                fontSize: 12,
              ),
              backgroundColor: inputBg,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog(IssueModel issue) {
    _noteController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text(
          'Add Admin Note',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _noteController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your note...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_noteController.text.trim().isNotEmpty) {
                await _dbService.addIssueNote(issue.id, _noteController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Note added successfully', accentGreen);
                  setState(() {}); // Refresh
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentBlue),
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(IssueModel issue, IssueStatus newStatus) async {
    try {
      await _dbService.updateIssueStatus(issue.id, newStatus);
      _showSnackBar('Status updated to ${_getStatusText(newStatus)}', accentGreen);
      setState(() => _selectedIssue = issue.copyWith(status: newStatus));
    } catch (e) {
      _showSnackBar('Error updating status: $e', accentRed);
    }
  }

  void _updatePriority(IssueModel issue, IssuePriority newPriority) async {
    try {
      await _dbService.updateIssuePriority(issue.id, newPriority);
      _showSnackBar('Priority updated to ${_getPriorityText(newPriority)}', accentGreen);
      setState(() => _selectedIssue = issue.copyWith(priority: newPriority));
    } catch (e) {
      _showSnackBar('Error updating priority: $e', accentRed);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
