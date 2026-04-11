import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/admin_models.dart';
import '../services/admin_database_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'admin_login_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_lessons_page.dart';
import 'pages/admin_word_groups_page.dart';
import 'pages/admin_learners_page.dart';
import 'pages/admin_analytics_page.dart';
import 'pages/admin_issues_page.dart';
import 'pages/admin_settings_page.dart';

/// Main navigation for admin portal with sidebar
class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();
  AdminModel? _admin;
  StreamSubscription<AdminModel?>? _adminSubscription;
  int _selectedIndex = 0;
  bool _isExpanded = true;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'DASHBOARD', color: AppTheme.signalYellow),
    _NavItem(icon: Icons.school_rounded, label: 'LESSONS', color: AppTheme.electricBlue),
    _NavItem(icon: Icons.text_fields_rounded, label: 'WORDS', color: AppTheme.mintGreen),
    _NavItem(icon: Icons.people_rounded, label: 'LEARNERS', color: AppTheme.softPeach),
    _NavItem(icon: Icons.analytics_rounded, label: 'ANALYTICS', color: AppTheme.signalYellow),
    _NavItem(icon: Icons.bug_report_rounded, label: 'ISSUES', color: AppTheme.punchRed),
    _NavItem(icon: Icons.settings_rounded, label: 'CONFIG', color: AppTheme.paperCream),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdmin();
  }

  @override
  void dispose() {
    _adminSubscription?.cancel();
    super.dispose();
  }

  void _initializeAdmin() {
    _adminSubscription = _adminDbService.adminStream().listen((admin) {
      if (mounted) setState(() => _admin = admin);
    });
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.inkBlack, width: 4),
        ),
        title: const Text('DISCONNECT?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('End your current control session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('BACK')),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: NeoButton(
              label: 'OFFLINE', 
              color: AppTheme.punchRed, 
              onPressed: () => Navigator.pop(context, true)
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminLoginPage()));
      }
    }
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0: return const AdminDashboardPage();
      case 1: return const AdminLessonsPage();
      case 2: return const AdminWordGroupsPage();
      case 3: return const AdminLearnersPage();
      case 4: return const AdminAnalyticsPage();
      case 5: return const AdminIssuesPage();
      case 6: return const AdminSettingsPage();
      default: return const AdminDashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) _buildDesktopSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile),
                Expanded(
                  child: Container(
                    color: AppTheme.paperCream,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutBack,
                      child: _buildCurrentPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.inkBlack, width: 4)),
      ),
      child: Row(
        children: [
          if (isMobile)
            _barButton(icon: Icons.menu_rounded, onTap: () => Scaffold.of(context).openDrawer()),
          const SizedBox(width: 16),
          Text(
            _navItems[_selectedIndex].label,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1),
          ),
          const Spacer(),
          _barButton(icon: Icons.notifications_rounded, onTap: () {}),
          const SizedBox(width: 16),
          _buildAdminProfile(),
        ],
      ),
    );
  }

  Widget _buildAdminProfile() {
    return GestureDetector(
      onTap: _signOut,
      child: NeoPanel(
        color: AppTheme.signalYellow,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.account_circle_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              _admin?.displayName.toUpperCase() ?? 'ADMIN',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 240 : 100,
      decoration: const BoxDecoration(
        color: AppTheme.charcoalNight,
        border: Border(right: BorderSide(color: AppTheme.inkBlack, width: 5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo
          Icon(Icons.terminal_rounded, color: AppTheme.signalYellow, size: _isExpanded ? 48 : 36),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, i) => _buildSidebarItem(i),
            ),
          ),
          _barButton(
            icon: _isExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            color: AppTheme.signalYellow,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int i) {
    final item = _navItems[i];
    final selected = _selectedIndex == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _onNavItemTapped(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? item.color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.inkBlack : Colors.transparent,
              width: 3,
            ),
          ),
          child: Row(
            mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: selected ? AppTheme.inkBlack : Colors.white60),
              if (_isExpanded) ...[
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected ? AppTheme.inkBlack : Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppTheme.paperCream,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.charcoalNight,
              border: Border(bottom: BorderSide(color: AppTheme.inkBlack, width: 4)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.terminal_rounded, color: AppTheme.signalYellow, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'KAIROAI CONTROL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _navItems.length,
              itemBuilder: (context, i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return ListTile(
                  onTap: () {
                    _onNavItemTapped(i);
                    Navigator.pop(context);
                  },
                  leading: Icon(item.icon, color: AppTheme.inkBlack),
                  title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w900)),
                  tileColor: selected ? item.color : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: selected ? const BorderSide(color: AppTheme.inkBlack, width: 2) : BorderSide.none,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: NeoButton(
              label: 'DISCONNECT',
              color: AppTheme.punchRed,
              onPressed: _signOut,
              icon: Icons.logout_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barButton({required IconData icon, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          border: Border.all(color: AppTheme.inkBlack, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.inkBlack, size: 24),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  const _NavItem({required this.icon, required this.label, required this.color});
}
