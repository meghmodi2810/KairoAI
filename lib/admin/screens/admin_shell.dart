import 'package:flutter/material.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_auth_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/main.dart';
import 'package:kairo_ai/admin/widgets/a_overlays.dart';
import 'package:kairo_ai/admin/screens/dashboard/admin_dashboard_screen.dart';
import 'package:kairo_ai/admin/screens/lessons/admin_lessons_screen.dart';
import 'package:kairo_ai/admin/screens/users/admin_users_screen.dart';
import 'package:kairo_ai/admin/screens/analytics/admin_analytics_screen.dart';
import 'package:kairo_ai/admin/screens/issues/admin_issues_screen.dart';
import 'package:kairo_ai/admin/screens/settings/admin_settings_screen.dart';

class AdminShell extends StatefulWidget {
  final AdminModel admin;

  const AdminShell({super.key, required this.admin});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  int _settingsTabIndex = 0;
  final List<int> _history = [0];
  final AdminAuthService _auth = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onTabSelected(int index, {int? settingsTab}) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      if (settingsTab != null) {
        _settingsTabIndex = settingsTab;
      } else if (index != 5) {
        _settingsTabIndex = 0;
      }
      _history.add(index);
    });
  }

  Future<void> _handleBack() async {
    // 1. If we have sub-navigation items or we're not on Dashboard, 
    // go back to the previous tab in history or the Dashboard.
    if (_selectedIndex != 0) {
      if (_history.length > 1) {
        setState(() {
          _history.removeLast();
          _selectedIndex = _history.last;
        });
      } else {
        _onTabSelected(0);
      }
      return;
    }

    // 2. If we are on the Dashboard (page 0), then we are attempting to exit the admin area.
    // The user explicitly requested an exit confirmation here.
    final confirm = await AdminConfirmModal.show(
      context,
      title: 'Exit Admin?',
      body: 'Are you sure you want to leave the admin panel?',
      confirmLabel: 'Exit',
    );
    
    if (confirm && mounted) {
      // Use system pop to exit to the student side or logout depending on app flow
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MyApp.themeProvider,
      builder: (context, _) {
        final bool isDarkMode = MyApp.themeProvider.isDarkMode;
        return Theme(
          data: isDarkMode ? adminThemeDark() : adminThemeLight(),
          child: Builder(
            builder: (context) {
              final c2 = ac(context);
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  _handleBack();
                },
                child: Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: c2.bgBase,
                  drawer: AdminDrawer(
                    adminName: widget.admin.displayName,
                    adminEmail: widget.admin.email,
                    selectedIndex: _selectedIndex,
                    onTabSelected: _onTabSelected,
                    onSignOut: _handleSignOut,
                  ),
                  body: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      AdminDashboardScreen(
                        admin: widget.admin,
                        onMenuTap: _openDrawer,
                        onTabChange: (idx, {subIndex}) =>
                            _onTabSelected(idx, settingsTab: subIndex),
                      ),
                      AdminLessonsScreen(
                        admin: widget.admin,
                        onMenuTap: _openDrawer,
                      ),
                      AdminUsersScreen(
                        admin: widget.admin,
                        onMenuTap: _openDrawer,
                      ),
                      AdminAnalyticsScreen(
                        admin: widget.admin,
                        onMenuTap: _openDrawer,
                      ),
                      AdminIssuesScreen(
                        admin: widget.admin,
                        onMenuTap: _openDrawer,
                      ),
                      AdminSettingsScreen(
                        admin: widget.admin,
                        onMenuTap: _openDrawer,
                        initialTabIndex: _settingsTabIndex,
                      ),
                    ],
                  ),
                  bottomNavigationBar: _selectedIndex < 5
                      ? AdminNavBar(
                          selectedIndex: _selectedIndex,
                          onTabSelected: _onTabSelected,
                        )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _handleSignOut() async {
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Sign out?',
      body: 'You will be returned to the login screen.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !mounted) return;

    // Sign out and navigate to login
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
