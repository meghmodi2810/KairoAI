import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/admin_models.dart';
import '../services/admin_database_service.dart';
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

  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
  static const Color primaryBlue = Color(0xFF1A2151);
  static const Color cardBg = Color(0xFF262F4D);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentBlue = Color(0xFF5CB6F9);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE57373);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentOrange = Color(0xFFFF9800);

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      color: accentYellow,
    ),
    _NavItem(
      icon: Icons.school_rounded,
      label: 'Lessons',
      color: accentBlue,
    ),
    _NavItem(
      icon: Icons.text_fields_rounded,
      label: 'Word Groups',
      color: accentGreen,
    ),
    _NavItem(
      icon: Icons.people_rounded,
      label: 'Learners',
      color: accentPurple,
    ),
    _NavItem(
      icon: Icons.analytics_rounded,
      label: 'Analytics',
      color: accentOrange,
    ),
    _NavItem(
      icon: Icons.bug_report_rounded,
      label: 'Issues',
      color: accentRed,
    ),
    _NavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      color: Colors.white70,
    ),
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
      if (mounted) {
        setState(() {
          _admin = admin;
        });
      }
    });
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white),
        ),
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
              backgroundColor: accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        );
      }
    }
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const AdminDashboardPage();
      case 1:
        return const AdminLessonsPage();
      case 2:
        return const AdminWordGroupsPage();
      case 3:
        return const AdminLearnersPage();
      case 4:
        return const AdminAnalyticsPage();
      case 5:
        return const AdminIssuesPage();
      case 6:
        return const AdminSettingsPage();
      default:
        return const AdminDashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: darkBlue,
      drawer: isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          // Sidebar (desktop only)
          if (!isMobile) _buildSidebar(),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                _buildAppBar(isMobile),
                // Page Content
                Expanded(child: _buildCurrentPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          if (!isMobile) const SizedBox(width: 8),
          Text(
            _navItems[_selectedIndex].label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white70),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: accentRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          const SizedBox(width: 8),
          // Admin Profile
          _buildProfileMenu(),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: accentYellow,
              child: Text(
                (_admin?.displayName ?? 'A')[0].toUpperCase(),
                style: const TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _admin?.displayName ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _admin?.role.displayName ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Text(
                'My Profile',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              Icon(Icons.logout, color: accentRed.withOpacity(0.9), size: 20),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(color: accentRed.withOpacity(0.9)),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'signout') {
          _signOut();
        }
      },
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 240 : 72,
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Header
          _buildSidebarHeader(),
          const Divider(color: Colors.white12, height: 1),
          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) => _buildNavItem(index),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Collapse Button
          _buildCollapseButton(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: accentYellow,
              size: 24,
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'KairoAI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 12 : 8,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNavItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 16 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? item.color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: item.color.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment:
                  _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? item.color : Colors.white54,
                  size: 22,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? item.color : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: IconButton(
        onPressed: () => setState(() => _isExpanded = !_isExpanded),
        icon: Icon(
          _isExpanded ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white54,
        ),
        tooltip: _isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: cardBg,
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryBlue, darkBlue],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accentYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: accentYellow,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'KairoAI Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _admin?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Nav Items
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
                    color: isSelected ? item.color : Colors.white54,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? item.color : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: item.color.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    _onNavItemTapped(index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          // Sign Out
          const Divider(color: Colors.white12, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: accentRed),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: accentRed),
            ),
            onTap: () {
              Navigator.pop(context);
              _signOut();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
