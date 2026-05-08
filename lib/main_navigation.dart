import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page_new.dart';
import 'pages/learn_page.dart';
import 'pages/words_page.dart';
import 'pages/profile_page.dart';
import 'theme/app_theme.dart';

class MainNavigationController extends ChangeNotifier {
  int? _pendingIndex;

  int? consumePendingIndex() {
    final index = _pendingIndex;
    _pendingIndex = null;
    return index;
  }

  void jumpTo(int index) {
    _pendingIndex = index;
    notifyListeners();
  }
}

class MainNavigationTourTargets {
  static final homeTab = GlobalKey(debugLabel: 'tour_home_tab');
  static final learnTab = GlobalKey(debugLabel: 'tour_learn_tab');
  static final wordsTab = GlobalKey(debugLabel: 'tour_words_tab');
  static final profileTab = GlobalKey(debugLabel: 'tour_profile_tab');
  static final profileIcon = GlobalKey(debugLabel: 'tour_profile_icon');

  static GlobalKey keyForIndex(int index) {
    return switch (index) {
      0 => homeTab,
      1 => learnTab,
      2 => wordsTab,
      _ => profileTab,
    };
  }
}

class MainNavigation extends StatefulWidget {
  final MainNavigationController? controller;

  const MainNavigation({super.key, this.controller});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Learn'),
    _NavItem(icon: Icons.style_rounded, label: 'Words'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  // Use IndexedStack so pages stay alive between tab switches
  final List<Widget> _pages = const [
    HomePage(),
    LearnPage(),
    WordsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleExternalNavigation);
  }

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleExternalNavigation);
      widget.controller?.addListener(_handleExternalNavigation);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleExternalNavigation);
    super.dispose();
  }

  void _handleExternalNavigation() {
    final nextIndex = widget.controller?.consumePendingIndex();
    if (nextIndex == null || nextIndex == _currentIndex) return;
    if (nextIndex < 0 || nextIndex >= _pages.length) return;
    setState(() => _currentIndex = nextIndex);
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        items: _items,
        onTap: _onTap,
      ),
    );
  }
}

// Brutalist control dock
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(14, 0, 14, (bottom > 0 ? bottom : 12)),
      height: 78,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.cardAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.isDark ? AppTheme.warmWhite : AppTheme.inkBlack,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.inkBlack,
            blurRadius: 0,
            offset: Offset(6, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                key: MainNavigationTourTargets.keyForIndex(i),
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.cobaltBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.isDark
                        ? AppTheme.warmWhite
                        : AppTheme.inkBlack,
                    width: selected ? 2.5 : 0,
                  ),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: AppTheme.inkBlack,
                            blurRadius: 0,
                            offset: Offset(3, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[i].icon,
                      key: i == 3
                          ? MainNavigationTourTargets.profileIcon
                          : null,
                      size: 22,
                      color: selected ? AppTheme.warmWhite : context.textMuted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        color: selected
                            ? AppTheme.warmWhite
                            : context.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
