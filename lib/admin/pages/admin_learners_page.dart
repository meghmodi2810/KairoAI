import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

class AdminLearnersPage extends StatefulWidget {
  const AdminLearnersPage({super.key});

  @override
  State<AdminLearnersPage> createState() => _AdminLearnersPageState();
}

class _AdminLearnersPageState extends State<AdminLearnersPage> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();
  LearnerModel? _selectedLearner;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildControlToolbar(),
              const Divider(height: 4, thickness: 4, color: AppTheme.inkBlack),
              Expanded(child: _buildLearnerManifest()),
            ],
          ),
        ),
        const VerticalDivider(width: 4, thickness: 4, color: AppTheme.inkBlack),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          width: _selectedLearner != null ? 420 : 0,
          color: AppTheme.paperCream,
          child: _selectedLearner != null ? _buildIdentityProfiler() : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildControlToolbar() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: NeoPanel(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'SEARCH SUBJECTS...', 
                  border: InputBorder.none, 
                  icon: Icon(Icons.radar_rounded)
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _statusFilter('ALL', 'all'),
          const SizedBox(width: 8),
          _statusFilter('ACTIVE', 'active'),
        ],
      ),
    );
  }

  Widget _statusFilter(String label, String val) {
    bool active = _filterStatus == val;
    return NeoButton(
      label: label,
      color: active ? AppTheme.signalYellow : Colors.white,
      onPressed: () => setState(() => _filterStatus = val),
    );
  }

  Widget _buildLearnerManifest() {
    return FutureBuilder<List<LearnerModel>>(
      future: _adminDbService.getLearners(),
      builder: (context, snapshot) {
        final learners = snapshot.data ?? [];
        final filtered = learners.where((l) {
          final matchesSearch = l.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                               l.email.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesFilter = _filterStatus == 'all' || (l.isActive == (_filterStatus == 'active'));
          return matchesSearch && matchesFilter;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _subjectCard(filtered[i]),
        );
      },
    );
  }

  Widget _subjectCard(LearnerModel subject) {
    bool selected = _selectedLearner?.uid == subject.uid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeoPanel(
        color: selected ? AppTheme.electricBlue.withValues(alpha: 0.1) : Colors.white,
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => setState(() => _selectedLearner = subject),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.charcoalNight,
                  border: Border.all(color: AppTheme.inkBlack, width: 3),
                ),
                child: subject.photoUrl != null
                    ? Image.network(subject.photoUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          subject.displayName[0].toUpperCase(), 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)
                        )
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.displayName.toUpperCase(), 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1)
                    ),
                    Text(
                      subject.email, 
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54, fontSize: 13)
                    ),
                  ],
                ),
              ),
              NeoSticker(
                label: subject.isActive ? 'OPERATIONAL' : 'OFFLINE',
                color: subject.isActive ? AppTheme.mintGreen : AppTheme.punchRed,
                icon: subject.isActive ? Icons.check_circle_rounded : Icons.block_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityProfiler() {
    final s = _selectedLearner!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IDENTITY PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              IconButton(
                onPressed: () => setState(() => _selectedLearner = null), 
                icon: const Icon(Icons.close_rounded, size: 32)
              ),
            ],
          ),
          const SizedBox(height: 32),
          _profileHeader(s),
          const SizedBox(height: 32),
          const Text('SYSTEM METRICS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 16),
          _metricGrid(s),
          const SizedBox(height: 32),
          NeoButton(
            label: s.isActive ? 'LOCK ACCESS' : 'GRANT ACCESS', 
            color: s.isActive ? AppTheme.punchRed : AppTheme.mintGreen, 
            onPressed: () {}
          ),
          const SizedBox(height: 12),
          NeoButton(label: 'COMPEL RE-AUTH', color: AppTheme.signalYellow, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _profileHeader(LearnerModel s) {
    return NeoPanel(
      color: AppTheme.charcoalNight,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(border: Border.all(color: AppTheme.signalYellow, width: 4)),
            child: s.photoUrl != null 
              ? Image.network(s.photoUrl!, fit: BoxFit.cover) 
              : const Icon(Icons.person_rounded, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            s.displayName.toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)
          ),
          const Text(
            'GLOBAL SUBJECT ID: REDACTED', 
            style: TextStyle(color: AppTheme.signalYellow, fontWeight: FontWeight.w900, fontSize: 10)
          ),
        ],
      ),
    );
  }

  Widget _metricGrid(LearnerModel s) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _metricTile('LEVEL', '${s.currentLevel}', AppTheme.electricBlue),
        _metricTile('STREAK', '${s.streakDays}', AppTheme.punchRed),
        _metricTile('GEMS', '${s.gems}', AppTheme.mintGreen),
        _metricTile('LESSONS', '${s.totalLessonsCompleted}', AppTheme.signalYellow),
      ],
    );
  }

  Widget _metricTile(String label, String val, Color col) {
    return NeoPanel(
      color: col.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: col)),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}
