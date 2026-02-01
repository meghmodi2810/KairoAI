import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';

/// Admin Learners Management Page - View and manage learner accounts
class AdminLearnersPage extends StatefulWidget {
  const AdminLearnersPage({super.key});

  @override
  State<AdminLearnersPage> createState() => _AdminLearnersPageState();
}

class _AdminLearnersPageState extends State<AdminLearnersPage> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();
  LearnerModel? _selectedLearner;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
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
      child: Row(
        children: [
          // Learners List
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildToolbar(),
                Expanded(child: _buildLearnersList()),
              ],
            ),
          ),
          // Selected Learner Details
          if (_selectedLearner != null)
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: _buildLearnerDetails(),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search learners...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: _filterStatus,
              dropdownColor: cardBg,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) => setState(() => _filterStatus = value ?? 'all'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnersList() {
    return FutureBuilder<List<LearnerModel>>(
      future: _adminDbService.getLearners(),
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
                  Icons.people_outline,
                  color: Colors.white.withOpacity(0.3),
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'No learners found',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        var learners = snapshot.data!;

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          learners = learners
              .where((l) =>
                  l.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  l.email.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // Filter by status
        if (_filterStatus == 'active') {
          learners = learners.where((l) => l.isActive).toList();
        } else if (_filterStatus == 'inactive') {
          learners = learners.where((l) => !l.isActive).toList();
        }

        if (learners.isEmpty) {
          return Center(
            child: Text(
              'No learners match your search',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: accentYellow,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: learners.length,
            itemBuilder: (context, index) {
              final learner = learners[index];
              return _buildLearnerCard(learner);
            },
          ),
        );
      },
    );
  }

  Widget _buildLearnerCard(LearnerModel learner) {
    final isSelected = _selectedLearner?.uid == learner.uid;

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
          onTap: () => setState(() => _selectedLearner = learner),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accentPurple.withOpacity(0.2),
                  backgroundImage: learner.photoUrl != null
                      ? NetworkImage(learner.photoUrl!)
                      : null,
                  child: learner.photoUrl == null
                      ? Text(
                          learner.displayName.isNotEmpty
                              ? learner.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: accentPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            learner.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: learner.isActive
                                  ? accentGreen.withOpacity(0.2)
                                  : accentRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              learner.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: learner.isActive ? accentGreen : accentRed,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        learner.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniStat(Icons.local_fire_department, '${learner.streakDays}', accentOrange),
                          const SizedBox(width: 12),
                          _buildMiniStat(Icons.trending_up, 'Lvl ${learner.currentLevel}', accentBlue),
                          const SizedBox(width: 12),
                          _buildMiniStat(Icons.diamond, '${learner.gems}', accentPurple),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLearnerDetails() {
    if (_selectedLearner == null) return const SizedBox();

    final learner = _selectedLearner!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Learner Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _selectedLearner = null),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Profile
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: accentPurple.withOpacity(0.2),
                  backgroundImage: learner.photoUrl != null
                      ? NetworkImage(learner.photoUrl!)
                      : null,
                  child: learner.photoUrl == null
                      ? Text(
                          learner.displayName.isNotEmpty
                              ? learner.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: accentPurple,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  learner.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  learner.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Level', '${learner.currentLevel}', Icons.trending_up, accentBlue),
              _buildStatCard('XP', '${learner.xp}', Icons.star, accentYellow),
              _buildStatCard('Streak', '${learner.streakDays}', Icons.local_fire_department, accentOrange),
              _buildStatCard('Gems', '${learner.gems}', Icons.diamond, accentPurple),
              _buildStatCard('Coins', '${learner.coins}', Icons.monetization_on, accentGreen),
              _buildStatCard('Lessons', '${learner.totalLessonsCompleted}', Icons.school, accentBlue),
            ],
          ),
          const SizedBox(height: 24),
          // Account Info
          _buildInfoSection('Account Information', [
            _buildInfoRow('Created', _formatDate(learner.createdAt)),
            _buildInfoRow('Last Login', _formatDate(learner.lastLoginAt)),
            _buildInfoRow('Learning Goal', learner.learningGoal ?? 'Not set'),
            _buildInfoRow('Daily Goal', '${learner.dailyGoalMinutes} minutes'),
          ]),
          const SizedBox(height: 24),
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleLearnerStatus(learner),
                  icon: Icon(learner.isActive ? Icons.block : Icons.check_circle),
                  label: Text(learner.isActive ? 'Deactivate' : 'Activate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: learner.isActive ? accentRed : accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _toggleLearnerStatus(LearnerModel learner) async {
    try {
      await _adminDbService.updateLearnerStatus(
        learner.uid,
        !learner.isActive,
      );
      _showSnackBar(
        learner.isActive ? 'Learner deactivated' : 'Learner activated',
        accentGreen,
      );
      setState(() => _selectedLearner = null);
    } catch (e) {
      _showSnackBar('Error: $e', accentRed);
    }
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
