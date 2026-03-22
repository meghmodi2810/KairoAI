import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page_new.dart';
import 'pages/learn_page.dart';
import 'pages/words_page.dart';
import 'pages/profile_page.dart';
import 'theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded,        label: 'Home'),
    _NavItem(icon: Icons.menu_book_rounded,   label: 'Learn'),
    _NavItem(icon: Icons.style_rounded,       label: 'Words'),
    _NavItem(icon: Icons.person_rounded,      label: 'Profile'),
  ];

  // Use IndexedStack so pages stay alive between tab switches
  final List<Widget> _pages = const [
    HomePage(),
    LearnPage(),
    WordsPage(),
    ProfilePage(),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        items: _items,
        onTap: _onTap,
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Floating pill nav bar
// ──────────────────────────────────────────────
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
      margin: EdgeInsets.fromLTRB(20, 0, 20, (bottom > 0 ? bottom : 16)),
      height: 64,
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
              child: AnimatedScale(
                scale: selected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: selected ? 44 : 36,
                      height: selected ? 44 : 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent.withOpacity(0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: selected
                            ? [BoxShadow(
                                color: AppTheme.accent.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                              )]
                            : null,
                      ),
                      child: Icon(
                        items[i].icon,
                        size: selected ? 22 : 20,
                        color: selected ? AppTheme.accent : context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: TextStyle(
                        color: selected ? AppTheme.accent : context.textMuted,
                        fontSize: selected ? 10 : 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      child: Text(items[i].label),
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
