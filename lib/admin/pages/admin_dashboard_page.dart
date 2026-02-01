import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../services/admin_auth_service.dart';
import '../services/admin_database_service.dart';
import '../../pages/login_page.dart';
import 'lessons/lessons_management_page.dart';
import 'word_groups/word_groups_management_page.dart';
import 'learners/learners_management_page.dart';
import 'analytics/analytics_page.dart';
import 'issues/issues_management_page.dart';
import 'settings/settings_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final AdminModel admin;

  const AdminDashboardPage({super.key, required this.admin});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminDatabaseService _dbService = AdminDatabaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  final List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.school_rounded, 'Lessons'),
    _NavItem(Icons.text_fields_rounded, 'Word Groups'),
    _NavItem(Icons.people_rounded, 'Learners'),
    _NavItem(Icons.analytics_rounded, 'Analytics'),
    _NavItem(Icons.report_problem_rounded, 'Issues'),
    _NavItem(Icons.settings_rounded, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final analytics = await _dbService.getAnalyticsSummary();
    if (mounted) {
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252A5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    
    return Theme(
      data: _buildAdminTheme(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF1A1F38),
        appBar: isWideScreen ? null : _buildAppBar(),
        drawer: isWideScreen ? null : _buildDrawer(),
        body: SafeArea(
          child: isWideScreen
              ? Row(
                  children: [
                    _buildSideNav(),
                    Expanded(child: _buildMainContent()),
                  ],
                )
              : _buildMainContent(),
        ),
        bottomNavigationBar: isWideScreen ? null : _buildBottomNav(),
      ),
    );
  }

  ThemeData _buildAdminTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF1A1F38),
      primaryColor: const Color(0xFFFFD93D),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFD93D),
        secondary: Color(0xFFFF6B9D),
        surface: Color(0xFF252A5E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A2151),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF252A5E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A2151),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD93D), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo/logo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFFFFD93D),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Admin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: _loadAnalytics,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A2151),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD93D), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo/logo.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.admin_panel_settings,
                          color: Color(0xFFFFD93D),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.admin.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD93D).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.admin.role.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD93D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _selectedIndex == index;
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected ? const Color(0xFFFFD93D) : Colors.white70,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFFFD93D) : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFFFD93D).withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 200,
      color: const Color(0xFF1A2151),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD93D), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo/logo.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.admin_panel_settings,
                        color: Color(0xFFFFD93D),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'KairoAI Admin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.admin.displayName,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: isSelected
                        ? const Color(0xFFFFD93D).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected ? const Color(0xFFFFD93D) : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? const Color(0xFFFFD93D) : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, size: 16, color: Colors.red),
                label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final bottomItems = _navItems.take(5).toList();
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A2151),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(bottomItems.length, (index) {
              final item = bottomItems[index];
              final isSelected = _selectedIndex == index;
              return InkWell(
                onTap: () => setState(() => _selectedIndex = index),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? const Color(0xFFFFD93D) : Colors.white54,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? const Color(0xFFFFD93D) : Colors.white54,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return LessonsManagementPage(admin: widget.admin);
      case 2:
        return WordGroupsManagementPage(admin: widget.admin);
      case 3:
        return LearnersManagementPage(admin: widget.admin);
      case 4:
        return AnalyticsPage(admin: widget.admin);
      case 5:
        return IssuesManagementPage(admin: widget.admin);
      case 6:
        return SettingsPage(admin: widget.admin);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: const Color(0xFFFFD93D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            const SizedBox(height: 20),
            _buildStatsCards(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildSystemStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${widget.admin.displayName.split(' ').first}!',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Here\'s your ISL platform overview.',
          style: TextStyle(fontSize: 13, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      _StatData('Learners', '${_analytics['totalLearners'] ?? 0}', Icons.people_rounded, const Color(0xFFFFD93D)),
      _StatData('Active', '${_analytics['activeLearners'] ?? 0}', Icons.trending_up_rounded, const Color(0xFF4CAF50)),
      _StatData('Issues', '${_analytics['openIssues'] ?? 0}', Icons.report_problem_rounded, const Color(0xFFFF9800)),
      _StatData('Content', '26+', Icons.library_books_rounded, const Color(0xFFFF6B9D)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index]),
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252A5E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoading ? '...' : stat.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                stat.label,
                style: const TextStyle(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252A5E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip('Add Lesson', Icons.add, const Color(0xFFFFD93D), () => setState(() => _selectedIndex = 1)),
              _buildActionChip('Learners', Icons.people, const Color(0xFF2196F3), () => setState(() => _selectedIndex = 3)),
              _buildActionChip('Analytics', Icons.analytics, const Color(0xFF4CAF50), () => setState(() => _selectedIndex = 4)),
              _buildActionChip('Settings', Icons.settings, Colors.white70, () => setState(() => _selectedIndex = 6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252A5E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Status',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(Icons.cloud_done, 'Firebase', 'Connected', const Color(0xFF4CAF50)),
          _buildStatusRow(Icons.storage, 'Database', 'Operational', const Color(0xFF4CAF50)),
          _buildStatusRow(Icons.verified_user, 'Role', widget.admin.role.replaceAll('_', ' '), const Color(0xFFFFD93D)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}
