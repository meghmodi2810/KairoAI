import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../widgets/admin_widgets.dart';
import '../../../models/app_models.dart';

class LearnersManagementPage extends StatefulWidget {
  final AdminModel admin;

  const LearnersManagementPage({super.key, required this.admin});

  @override
  State<LearnersManagementPage> createState() => _LearnersManagementPageState();
}

class _LearnersManagementPageState extends State<LearnersManagementPage> {
  final AdminDatabaseService _dbService = AdminDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<UserModel> _learners = [];
  bool _isLoading = true;
  bool _hasMore = true;
  String? _lastDocId;

  @override
  void initState() {
    super.initState();
    _loadLearners();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreLearners();
    }
  }

  Future<void> _loadLearners({bool refresh = false}) async {
    if (refresh) {
      _lastDocId = null;
      _hasMore = true;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final learners = await _dbService.getLearnersPaginated(limit: 20);
      if (mounted) {
        setState(() {
          _learners = learners;
          _isLoading = false;
          _hasMore = learners.length >= 20;
          if (learners.isNotEmpty) _lastDocId = learners.last.uid;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadMoreLearners() async {
    if (!_hasMore || _isLoading || _lastDocId == null) return;

    setState(() => _isLoading = true);
    
    try {
      final more = await _dbService.getLearnersPaginated(limit: 20, startAfterDocId: _lastDocId);
      if (mounted) {
        setState(() {
          _learners.addAll(more);
          _isLoading = false;
          _hasMore = more.length >= 20;
          if (more.isNotEmpty) _lastDocId = more.last.uid;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UserModel> get _filteredLearners {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _learners;
    return _learners.where((l) => l.displayName.toLowerCase().contains(query) || l.email.toLowerCase().contains(query)).toList();
  }

  bool _isActiveToday(UserModel user) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return user.lastLoginAt.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildLearnersList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount = _learners.where((l) => _isActiveToday(l)).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Learners', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                    SizedBox(height: 2),
                    Text('Manage user accounts', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _loadLearners(refresh: true),
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _buildMiniStat(Icons.people, '${_learners.length}${_hasMore ? '+' : ''}', 'Total'),
              const SizedBox(width: 12),
              _buildMiniStat(Icons.trending_up, '$activeCount', 'Active'),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search learners...',
              hintStyle: const TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20, color: AdminTheme.textSecondary),
              filled: true,
              fillColor: AdminTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchController.clear(); setState(() {}); })
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: AdminTheme.accentYellow, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearnersList() {
    if (_isLoading && _learners.isEmpty) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow)));
    }

    final filtered = _filteredLearners;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_off, size: 48, color: AdminTheme.textSecondary),
            SizedBox(height: 12),
            Text('No Learners Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadLearners(refresh: true),
      color: AdminTheme.accentYellow,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length + (_hasMore && !_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow))),
            );
          }
          return _buildLearnerCard(filtered[index]);
        },
      ),
    );
  }

  Widget _buildLearnerCard(UserModel learner) {
    final isActive = _isActiveToday(learner);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showLearnerDetails(learner),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AdminTheme.primaryBlue,
                    backgroundImage: (learner.photoUrl?.isNotEmpty ?? false) ? NetworkImage(learner.photoUrl!) : null,
                    child: (learner.photoUrl?.isEmpty ?? true)
                        ? Text(
                            learner.displayName.isNotEmpty ? learner.displayName[0].toUpperCase() : '?',
                            style: const TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                          )
                        : null,
                  ),
                  if (isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AdminTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AdminTheme.cardBg, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learner.displayName.isNotEmpty ? learner.displayName : 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(learner.email, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatChip(Icons.stars, 'Lv ${learner.currentLevel}', AdminTheme.accentYellow),
                        const SizedBox(width: 6),
                        _buildStatChip(Icons.local_fire_department, '${learner.streakDays}d', AdminTheme.accentPink),
                        const SizedBox(width: 6),
                        _buildStatChip(Icons.diamond, '${learner.gems}', AdminTheme.info),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AdminTheme.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showLearnerDetails(UserModel learner) {
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
        builder: (_, controller) => _buildLearnerDetailsSheet(learner, controller),
      ),
    );
  }

  Widget _buildLearnerDetailsSheet(UserModel learner, ScrollController controller) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AdminTheme.primaryBlue,
                backgroundImage: (learner.photoUrl?.isNotEmpty ?? false) ? NetworkImage(learner.photoUrl!) : null,
                child: (learner.photoUrl?.isEmpty ?? true)
                    ? Text(learner.displayName.isNotEmpty ? learner.displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(learner.displayName.isNotEmpty ? learner.displayName : 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(learner.email, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isActiveToday(learner) ? AdminTheme.success.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isActiveToday(learner) ? 'Active Today' : 'Offline',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isActiveToday(learner) ? AdminTheme.success : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Grid
          const Text('Stats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildStatBox(Icons.stars, '${learner.currentLevel}', 'Level', AdminTheme.accentYellow),
              _buildStatBox(Icons.bolt, '${learner.xp}', 'XP', AdminTheme.accentPink),
              _buildStatBox(Icons.diamond, '${learner.gems}', 'Gems', AdminTheme.info),
              _buildStatBox(Icons.monetization_on, '${learner.coins}', 'Coins', AdminTheme.success),
              _buildStatBox(Icons.local_fire_department, '${learner.streakDays}', 'Streak', AdminTheme.warning),
              _buildStatBox(Icons.school, '${learner.totalLessonsCompleted}', 'Lessons', AdminTheme.accentPink),
            ],
          ),
          const SizedBox(height: 20),
          // Details
          const Text('Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          _buildDetailRow('Last Active', _formatDateTime(learner.lastLoginAt)),
          _buildDetailRow('Joined', _formatDate(learner.createdAt)),
          _buildDetailRow('Signs Learned', '${learner.totalSignsLearned}'),
          _buildDetailRow('Practice Minutes', '${learner.totalPracticeMinutes}'),
          _buildDetailRow('Daily Goal', '${learner.dailyGoalMinutes} min'),
          const SizedBox(height: 20),
          // Actions
          const Text('Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(context); _showAdjustGemsDialog(learner); },
                  icon: const Icon(Icons.diamond, size: 16),
                  label: const Text('Gems'),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.info, side: const BorderSide(color: AdminTheme.info)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(context); _confirmResetProgress(learner); },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.warning, side: const BorderSide(color: AdminTheme.warning)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(context); _confirmDeleteAccount(learner); },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.error, side: const BorderSide(color: AdminTheme.error)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, color: AdminTheme.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _formatDateTime(DateTime date) => '${_formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

  void _confirmResetProgress(UserModel learner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Progress?', style: TextStyle(color: Colors.white)),
        content: Text('Clear all progress for ${learner.displayName}?', style: const TextStyle(color: AdminTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.warning),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.resetLearnerProgress(learner.uid);
      _loadLearners(refresh: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress reset!')));
    }
  }

  void _showAdjustGemsDialog(UserModel learner) {
    final controller = TextEditingController();
    bool isAdding = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Adjust Gems', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: ${learner.gems} gems', style: const TextStyle(color: AdminTheme.textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(label: const Text('Add'), selected: isAdding, onSelected: (_) => setDialogState(() => isAdding = true)),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Remove'), selected: !isAdding, onSelected: (_) => setDialogState(() => isAdding = false)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(controller.text) ?? 0;
                if (amount > 0) {
                  final newGems = isAdding ? learner.gems + amount : (learner.gems - amount).clamp(0, double.infinity).toInt();
                  await _dbService.updateLearner(learner.uid, {'gems': newGems});
                  _loadLearners(refresh: true);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAdding ? 'Added $amount gems' : 'Removed $amount gems')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accentYellow, foregroundColor: AdminTheme.primaryDark),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(UserModel learner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
        content: Text('Permanently delete ${learner.displayName}\'s account?', style: const TextStyle(color: AdminTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteLearner(learner.uid);
      _loadLearners(refresh: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted!')));
    }
  }
}
