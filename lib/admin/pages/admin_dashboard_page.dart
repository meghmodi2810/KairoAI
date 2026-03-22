import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_models.dart';
import '../services/admin_auth_service.dart';
import '../services/admin_database_service.dart';
import '../../pages/login_page.dart';
import 'categories/categories_management_page.dart';
import 'lessons/lessons_management_page.dart';
import 'signs/signs_management_page.dart';
import 'word_groups/word_groups_management_page.dart';
import 'learners/learners_management_page.dart';
import 'analytics/analytics_page.dart';
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

  // Simplified nav: 6 essential items (down from 9)
  static const List<_NavItem> _navItems = [
    _NavItem(Icons.grid_view_rounded, 'Dashboard'),
    _NavItem(Icons.folder_rounded, 'Content'),   // Categories + Lessons merged
    _NavItem(Icons.sign_language_rounded, 'Signs'),
    _NavItem(Icons.people_outline, 'Learners'),
    _NavItem(Icons.bar_chart_rounded, 'Analytics'),
    _NavItem(Icons.settings_outlined, 'Settings'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    final isWide = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isWide ? null : AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: cs.onSurface.withOpacity(0.6)), onPressed: _loadAnalytics),
          IconButton(icon: Icon(Icons.logout, color: cs.onSurface.withOpacity(0.6)), onPressed: _handleLogout),
        ],
      ),
      drawer: isWide ? null : _buildDrawer(theme, cs),
      body: SafeArea(
        child: isWide
            ? Row(children: [
                _buildSideRail(theme, cs),
                Expanded(child: _buildMainContent()),
              ])
            : _buildMainContent(),
      ),
      bottomNavigationBar: isWide ? null : _buildBottomNav(theme, cs),
    );
  }

  // ── Minimal side rail for wide screens ──
  Widget _buildSideRail(ThemeData theme, ColorScheme cs) {
    return Container(
      width: 72,
      color: cs.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primary,
            child: Text(
              widget.admin.displayName.isNotEmpty ? widget.admin.displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ..._navItems.asMap().entries.map((e) {
            final isSelected = _selectedIndex == e.key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: IconButton(
                onPressed: () => setState(() => _selectedIndex = e.key),
                icon: Icon(e.value.icon, size: 22),
                color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.45),
                tooltip: e.value.label,
              ),
            );
          }),
          const Spacer(),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 20),
            color: Colors.redAccent,
            tooltip: 'Sign Out',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Clean drawer ──
  Widget _buildDrawer(ThemeData theme, ColorScheme cs) {
    return Drawer(
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: cs.primary,
                    child: Text(
                      widget.admin.displayName.isNotEmpty ? widget.admin.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.admin.displayName, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                        Text(widget.admin.role.replaceAll('_', ' '), style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: cs.onSurface.withOpacity(0.1)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _selectedIndex == index;
                  return ListTile(
                    leading: Icon(item.icon, color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.6), size: 22),
                    title: Text(item.label, style: TextStyle(color: isSelected ? cs.primary : cs.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
                    selected: isSelected,
                    selectedTileColor: cs.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4-tab bottom nav (mobile) ──
  Widget _buildBottomNav(ThemeData theme, ColorScheme cs) {
    // Show 4 key items on bottom nav: Dashboard, Content, Learners, Settings
    const bottomMap = [0, 1, 3, 5]; // indices into _navItems
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.08))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: bottomMap.map((realIndex) {
              final item = _navItems[realIndex];
              final isSelected = _selectedIndex == realIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = realIndex),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.4), size: 22),
                      const SizedBox(height: 3),
                      Text(item.label, style: TextStyle(fontSize: 10, color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.4), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
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
        return _ContentTab(admin: widget.admin);
      case 2:
        return SignsManagementPage(admin: widget.admin);
      case 3:
        return LearnersManagementPage(admin: widget.admin);
      case 4:
        return AnalyticsPage(admin: widget.admin);
      case 5:
        return SettingsPage(admin: widget.admin);
      default:
        return _buildDashboard();
    }
  }

  // ── Clean dashboard ──
  Widget _buildDashboard() {
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: cs.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(cs),
            const SizedBox(height: 24),
            _buildStatsGrid(cs),
            const SizedBox(height: 24),
            _buildQuickActions(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(ColorScheme cs) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${widget.admin.displayName.split(' ').first}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        Text('Here\'s your platform overview.', style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildStatsGrid(ColorScheme cs) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _StatTile(label: 'Learners', stream: FirebaseFirestore.instance.collection('users').snapshots(), color: cs.primary),
        _StatTile(label: 'Categories', stream: FirebaseFirestore.instance.collection('categories').snapshots(), color: const Color(0xFF22C55E)),
        _StatTile(label: 'Word Groups', stream: FirebaseFirestore.instance.collection('word_groups').snapshots(), color: const Color(0xFFF472B6)),
        _buildIssueCard(cs),
      ],
    );
  }

  Widget _buildIssueCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Issues', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
          Text(
            _isLoading ? '…' : '${_analytics['openIssues'] ?? 0}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChip(label: 'Content', onTap: () => setState(() => _selectedIndex = 1), color: cs.primary),
            _ActionChip(label: 'Learners', onTap: () => setState(() => _selectedIndex = 3), color: const Color(0xFF22C55E)),
            _ActionChip(label: 'Analytics', onTap: () => setState(() => _selectedIndex = 4), color: const Color(0xFF38BDF8)),
          ],
        ),
      ],
    );
  }
}

// ── Merged Content tab: Categories → Lessons → Signs flow ──
class _ContentTab extends StatefulWidget {
  final AdminModel admin;
  const _ContentTab({required this.admin});

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(10)),
            labelColor: Colors.white,
            unselectedLabelColor: cs.onSurface.withOpacity(0.5),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            dividerHeight: 0,
            tabs: const [Tab(text: 'Categories'), Tab(text: 'Lessons'), Tab(text: 'Word Groups')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              CategoriesManagementPage(admin: widget.admin),
              LessonsManagementPage(admin: widget.admin),
              WordGroupsManagementPage(admin: widget.admin),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tiny reusable widgets ──

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _StatTile extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot> stream;
  final Color color;
  const _StatTile({required this.label, required this.stream, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
              Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionChip({required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
